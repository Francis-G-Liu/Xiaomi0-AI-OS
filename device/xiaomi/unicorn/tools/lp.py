#!/usr/bin/env python3 -I
#
# liblp super partition parser & extractor.
# Reads the Android logical partition metadata format from system/fs/fs_mgr/liblp
# (structs LpMetadataGeometry, LpMetadataHeader, LpMetadataPartition,
#  LpMetadataExtent, LpMetadataPartitionGroup, LpMetadataBlockDevice).
#
# Usage:
#   lp.py info   <super.img>          # print partition table
#   lp.py extract <super.img> <dir>    # write each partition image into <dir>/
#
# Field offsets/sizes match metadata_format.h in Android 17 (liblp v10.2).
#
import struct, sys, hashlib, os

GEOMETRY_MAGIC   = 0x616c4467   # "gDla"
HEADER_MAGIC     = 0x414C5030   # "0LPA"
GEOMETRY_SIZE    = 4096
SECTOR           = 512
RESERVED_BYTES   = 4096         # LP_PARTITION_RESERVED_BYTES
# Layout: [0,4096) reserved zeros, geometry copy0 @4096, geometry copy1 @8192,
# then metadata slots at 12288.  Primary copy of slot 0 is at 12288.
GEOMETRY_OFFSET  = RESERVED_BYTES                    # 4096
METADATA_OFFSET  = RESERVED_BYTES + 2 * GEOMETRY_SIZE  # 12288
HEADER_SIZE_V1_2 = 256          # full packed LpMetadataHeader incl. flags+reserved

# (name, size_in_sectors, target_type, target_data_sector, target_source)
PART_FMT = "<36sIIII"           # 52 bytes  (packed -> no padding, use declared entry size for stride)
EXT_FMT  = "<QIQI"             # 24 bytes: num_sectors:Q, target_type:I, target_data:Q, target_source:I
GROUP_FMT = "<36sIQ"           # 48 bytes
BLKDEV_FMT = "<QIIQ36sI"       # 64 bytes
DESC_FMT  = "<III"             # table descriptor: offset, num_entries, entry_size

# packed sizes (struct.calcsize)
SZ_PART, SZ_EXT, SZ_GROUP, SZ_BLKDEV, SZ_DESC = (struct.calcsize(f) for f in
        (PART_FMT, EXT_FMT, GROUP_FMT, BLKDEV_FMT, DESC_FMT))


def _cstr(b):
    return b.split(b'\x00', 1)[0].decode('ascii', 'replace')


def parse_geometry(d):
    g = d[:GEOMETRY_SIZE]
    magic, struct_size = struct.unpack_from('<II', g, 0)
    if magic != GEOMETRY_MAGIC:
        raise ValueError("bad geometry magic 0x%x" % magic)
    checksum = g[8:40]
    # checksum covers only the packed struct, with the checksum field zeroed
    body = bytearray(g[:struct_size])
    body[8:40] = b'\x00' * 32
    if hashlib.sha256(bytes(body)).digest() != checksum:
        sys.stderr.write("warning: geometry checksum mismatch\n")
    metadata_max_size, slot_count, logical_block_size = struct.unpack_from('<III', g, 40)
    return metadata_max_size, slot_count, logical_block_size


def parse_header(meta):
    magic, major, minor, header_size = struct.unpack_from('<IHHI', meta, 0)
    if magic != HEADER_MAGIC:
        raise ValueError("bad header magic 0x%x" % magic)
    tables_size = struct.unpack_from('<I', meta, 44)[0]
    descs = {}
    names = ['partitions', 'extents', 'groups', 'block_devices']
    off = 80
    for n in names:
        o, num, esize = struct.unpack_from(DESC_FMT, meta, off)
        descs[n] = (o, num, esize)
        off += SZ_DESC
    flags = struct.unpack_from('<I', meta, 128)[0] if header_size >= 128 else 0
    return major, minor, header_size, tables_size, descs, flags


def parse(super_path):
    with open(super_path, 'rb') as f:
        d = f.read()
    g = d[GEOMETRY_OFFSET:GEOMETRY_OFFSET + GEOMETRY_SIZE]
    parse_geometry(g)
    # primary metadata copy lives right after the two geometry blocks
    meta_off = METADATA_OFFSET
    # header_size tells us where tables begin
    hdr = d[meta_off:meta_off + HEADER_SIZE_V1_2]
    major, minor, header_size, tables_size, descs, flags = parse_header(hdr)
    tables = d[meta_off + header_size: meta_off + header_size + tables_size]
    parts = []
    o, num, esize = descs['partitions']
    raw = tables[o:o + num * esize]
    for i in range(num):
        name, attrs, first_ext, num_ext, grp = struct.unpack_from(PART_FMT, raw, i * esize)
        parts.append(dict(name=_cstr(name), attributes=attrs,
                          first_extent=first_ext, num_extents=num_ext, group=grp))
    exts = []
    o, num, esize = descs['extents']
    raw = tables[o:o + num * esize]
    for i in range(num):
        ns, tt, td, ts = struct.unpack_from(EXT_FMT, raw, i * esize)
        exts.append(dict(num_sectors=ns, target_type=tt, target_data=td, target_source=ts))
    groups = []
    o, num, esize = descs['groups']
    raw = tables[o:o + num * esize]
    for i in range(num):
        name, fl, mx = struct.unpack_from(GROUP_FMT, raw, i * esize)
        groups.append(dict(name=_cstr(name), flags=fl, maximum_size=mx))
    blks = []
    o, num, esize = descs['block_devices']
    raw = tables[o:o + num * esize]
    for i in range(num):
        fls, align, aoff, size, pname, bf = struct.unpack_from(BLKDEV_FMT, raw, i * esize)
        blks.append(dict(first_logical_sector=fls, alignment=align,
                         alignment_offset=aoff, size=size,
                         partition_name=_cstr(pname), flags=bf))
    # build partition -> byte ranges on the super image
    out = []
    for p in parts:
        size_sectors = 0
        extents = []
        for e in exts[p['first_extent']:p['first_extent'] + p['num_extents']]:
            size_sectors += e['num_sectors']
            if e['target_type'] == 0:  # LINEAR
                extents.append((e['target_data'] * SECTOR, e['num_sectors'] * SECTOR))
        out.append(dict(name=p['name'], group=groups[p['group']]['name'] if p['group'] < len(groups) else '?',
                        size_bytes=size_sectors * SECTOR, extents=extents,
                        attributes=p['attributes']))
    return out, blks, (major, minor), flags


def cmd_info(path):
    parts, blks, ver, flags = parse(path)
    print("super: %s" % path)
    print("metadata version: %d.%d  flags: 0x%x" % (ver[0], ver[1], flags))
    for b in blks:
        print("  block_device %-8s first_logical_sector=%d size=%d align=%d"
              % (b['partition_name'] or 'super', b['first_logical_sector'], b['size'], b['alignment']))
    print()
    fmt = "  %-14s %-28s %12s  %-16s %s"
    print(fmt % ("partition", "group", "size_bytes", "attributes", "extents"))
    for p in parts:
        print(fmt % (p['name'], p['group'], p['size_bytes'],
                     "0x%x" % p['attributes'],
                     ",".join("L@%d+%d" % (o, s) for o, s in p['extents']) or "(zero)"))


def cmd_extract(path, outdir):
    parts, blks, ver, flags = parse(path)
    os.makedirs(outdir, exist_ok=True)
    with open(path, 'rb') as f:
        for p in parts:
            nm = p['name']
            # strip slot suffix (_a/_b) when present so we emit stable names
            base = nm[:-2] if nm.endswith(('_a', '_b')) else nm
            outp = os.path.join(outdir, base + '_a.img')
            with open(outp, 'wb') as o:
                if not p['extents']:
                    o.truncate(p['size_bytes'])
                    continue
                for off, sz in p['extents']:
                    f.seek(off)
                    remaining = sz
                    while remaining > 0:
                        chunk = f.read(min(1 << 20, remaining))
                        if not chunk:
                            break
                        o.write(chunk)
                        remaining -= len(chunk)
            print("  %s -> %s (%d bytes)" % (nm, outp, p['size_bytes']))


def main(argv):
    if len(argv) < 3:
        sys.stderr.write("usage: lp.py info <super.img> | extract <super.img> <dir>\n")
        return 2
    cmd, path = argv[1], argv[2]
    if cmd == 'info':
        cmd_info(path)
    elif cmd == 'extract':
        cmd_extract(path, argv[3] if len(argv) > 3 else '.')
    else:
        sys.stderr.write("unknown command %r\n" % cmd)
        return 2
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv))
