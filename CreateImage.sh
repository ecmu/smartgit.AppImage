#! /bin/bash

#=== Get App

URL=$(wget --quiet "https://www.syntevo.com/smartgit/download/" -O - | grep -e "smartgit-linux-.*.tar.gz" | head -n 1 | cut -d '"' -f 2)
wget --continue "https://www.syntevo.com${URL}" || exit 1
tar xf smartgit-linux-*.tar.gz || exit 1

#=== Copy to AppDir

APPDIR=$(readlink -f appdir)
mkdir --parents ${APPDIR}/usr
cp --recursive smartgit/* ${APPDIR}/usr

cp ${APPDIR}/usr/bin/smartgit.svg ${APPDIR}

#=== Create app.desktop
#See "add-menuitem.sh"

cat << EOF > ${APPDIR}/smartgit.desktop
[Desktop Entry]
Version=1.0
Encoding=UTF-8
Name=SmartGit
Keywords=git;
Comment=Git-Client
Type=Application
Categories=Development;RevisionControl;
Terminal=false
StartupNotify=true
StartupWMClass=SmartGit
Exec=smartgit.sh %u
MimeType=x-scheme-handler/git;x-scheme-handler/smartgit;x-scheme-handler/sourcetree;
Icon=smartgit
EOF

#=== Create AppRun script

cat << EOF > ${APPDIR}/AppRun
#!/usr/bin/env bash
echo "APPDIR = \${APPDIR}"
echo "APPIMAGE = \${APPIMAGE}"
echo "ARGV0 = \${ARGV0}"
echo "PATH = \${PATH}"

HERE="\$(dirname "\$(readlink -f "\${0}")")"
echo "HERE = \${HERE}"

#=======================================================================

#echo "jre=\${HERE}/usr/jre" >>\${HERE}/usr/bin/smartgit.vmoptions

#=======================================================================

bash \${HERE}/usr/bin/smartgit.sh \$@
EOF

chmod a+x ${APPDIR}/AppRun

#=== Construit l'image

export VERSION=$(ls smartgit-linux-*.tar.gz | sed -r 's/.*smartgit-linux-(.*).tar.gz/\1/')

wget --continue "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage"
chmod +x appimagetool-x86_64.AppImage

./appimagetool-x86_64.AppImage ${APPDIR}
