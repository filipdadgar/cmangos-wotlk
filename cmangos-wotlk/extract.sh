#/bin/bash
docker run -d -p8085:8085 -p3724:3724 -v /home/filip/client:/cmangos/bin/client -v /media/download/kubeconfig/mangos-wotlk/:/cmangos/bin/nas filipdadgar/mangos-wotlk
