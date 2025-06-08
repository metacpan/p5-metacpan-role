# Author notes:

dzil authordeps --missing | cpanm --notest
dzil listdeps --missing | cpanm --notest


docker build -t perl-mc-role .
docker run -it --rm -v $(pwd):/app perl-mc-role 

dzil build
dzil test
```