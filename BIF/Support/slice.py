import os
import sys
import subprocess
import shutil
import json
import re

INPUT_FILE = sys.argv[1]
ASSETS_FILE = sys.argv[2]

OUTPUT_DIR = os.path.join(ASSETS_FILE, 'Slices')

if os.path.exists(OUTPUT_DIR):
    shutil.rmtree(OUTPUT_DIR)
os.makedirs(OUTPUT_DIR)

subprocess.call([
    'sketchtool',
    'export',
    'slices',
    INPUT_FILE,
    '--output=' + OUTPUT_DIR,
])

slices = {}
for filename in os.listdir(OUTPUT_DIR):
    slice_name_matches = re.search("([^.@]+)", filename, re.S)
    slice_name = slice_name_matches.group(0)
    slices_for_slice_name = slices.get(slice_name, [])
    asset_path = os.path.join(OUTPUT_DIR, filename)
    slices_for_slice_name.append(asset_path)
    slices[slice_name] = slices_for_slice_name

for slice_name, asset_paths in slices.iteritems():
    slice_directory_name = slice_name + ".imageset"
    slice_directory = os.path.join(OUTPUT_DIR, slice_directory_name)
    os.makedirs(slice_directory)
    for asset_path in asset_paths:
        shutil.move(asset_path, slice_directory)
    info = {
        'images': [
            {
                'idiom': 'universal',
                'scale': '1x',
                'filename': slice_name + '.png',
            },
            {
                'idiom': 'universal',
                'scale': '2x',
                'filename': slice_name + '@2x.png',
            },
            {
                'idiom': 'universal',
                'scale': '3x',
                'filename': slice_name + '@3x.png',
            },
        ],
        'info': {
            'version': 1,
            'author': 'xcode',
        },
    }
    output_file_path = os.path.join(slice_directory, 'Contents.json')
    output_file = open(output_file_path, 'w+')
    output_file.write(json.dumps(info))
    output_file.close()

