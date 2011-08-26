#!/bin/sh
#
if [ "x$1" = x ]; then
  echo $0: need version number
  exit 1
fi
newv=$1
reldir=$HOME/release
reltar=remark-${newv}.tar.gz
reldist=${reldir}/${reltar}
wwwdir=$HOME/hawg/www/remark
wwwfile=${wwwdir}/${reltar}
if [ ! -f ${reldist} ]; then
  echo $0: no reldir ${reldir}
  exit 1
fi
echo copying ${reldist} ...
cp ${reldist} ${wwwfile}
cd ${wwwdir}
echo generating md5 ...
md5 ${reltar} > ${reltar}.md5
echo signing
gpg --detach-sign --armor ${reltar}
if [ "x$2" = x ]; then
  echo making latest
  rm remark-latest.* || exit 1
  ln -s ${reltar} remark-latest.tar.gz
  ln -s ${reltar}.md5 remark-latest.tar.gz.md5
  ln -s ${reltar}.asc remark-latest.tar.gz.asc
fi
echo marking latest
latest="`echo ${newv} | tr . _`"
rm -f LATEST_IS_*
touch LATEST_IS_${latest}
cd
echo copying back md5 and signature
cp ${wwwdir}/${reltar}.md5 ${reldir}
cp ${wwwdir}/${reltar}.asc ${reldir}
echo done.
