#!/bin/bash

source config.sh

#...Update the default replicated rule to be osd failure domain
ceph osd getcrushmap -o compiled_crushmap.cm
crushtool -d compiled_crushmap.cm -o decompiled_crushmap.cm
perl -w -pi -e "s/type\ host/type\ osd/g" decompiled_crushmap.cm
crushtool -c decompiled_crushmap.cm -o compiled_crushmap.cm
ceph osd setcrushmap -i compiled_crushmap.cm

if [ $save_crushmap_temporaries -eq 0 ]; then
    rm -f compiled_crushmap.cm decompiled_crushmap.cm
fi
