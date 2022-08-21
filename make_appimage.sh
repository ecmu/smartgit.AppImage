#!/usr/bin/env bash
set -x #echo on
set -e #Exists on errors

SCRIPTPATH=$(cd $(dirname "$BASH_SOURCE") && pwd)
echo "SCRIPTPATH = $SCRIPTPATH"

export APP=GnuCash
export LOWERAPP=gnucash
export APPDIR="${SCRIPTPATH}/appdir"

#=== Define App version to build

#Workaround for build outside github: "env" file should then contain exports of github variables.
if [ -f "./env" ];
then
  source ./env
fi

if [ "$GITHUB_REF_NAME" = "" ];
then
	echo "Please define tag for this release (GITHUB_REF_NAME)"
	exit 1
fi

export VERSION="$GITHUB_REF_NAME"

#Get App version from tag, excluding suffixe "-Revision" used only for specific AppImage builds...
VERSION_SRC=$(echo $GITHUB_REF_NAME | cut -d'-' -f1)
#And here replacing "." by "_" for the download URL.
VERSION_SRC=${VERSION_SRC//./_}
echo "VERSION_SRC = $VERSION_SRC"

#=== Get App

pushd ${SCRIPTPATH}

TarName="smartgit-linux-${VERSION_SRC}.tar.gz"
if [ ! -f "./${TarName}" ];
then
	wget --continue "https://www.syntevo.com/downloads/smartgit/${TarName}"
fi

AppSrcDir="./smartgit"
if [ ! -d "$AppSrcDir" ];
then
  tar xf "${TarName}"
fi

#=== Copy to AppDir

mkdir --parents ${APPDIR}/usr
cp --recursive $AppSrcDir/* "${APPDIR}/usr"

cp "${APPDIR}/usr/bin/smartgit.svg" "${APPDIR}"

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
StartupWMClass=SmartGit
Exec=smartgit.sh %u
MimeType=x-scheme-handler/git;x-scheme-handler/smartgit;
Icon=smartgit
EOF

#=== Create AppRun script

cat << EOF > ${APPDIR}/AppRun
#!/usr/bin/env bash

export APPDIR="\${APPDIR:-"\$(dirname "\$(realpath "\$0")")"}" # Workaround to run extracted AppImage
#export PATH="\${APPDIR}/usr/bin":\$PATH

bash \${APPDIR}/usr/bin/smartgit.sh \$@
EOF

chmod a+x ${APPDIR}/AppRun

#=== Construit l'image

wget --continue "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage"
chmod +x appimagetool-x86_64.AppImage

./appimagetool-x86_64.AppImage ${APPDIR}

popd
