#!/bin/bash

set -ue
SRC_PATH=$(readlink -e $(dirname $0))


print_usage() {
	echo "usage: $0 [-o OUTPUT_THEME_NAME] [-p PATH_LIST] [-m MAKE_OPTS] PRESET_NAME_OR_PATH"
	echo "examples:"
	echo "       $0 monovedek"
	echo "       $0 -o my-theme-name ./colors/retro/twg"
	echo "       $0 -o oomox-gnome-noble -p \"./gtk-2.0 ./gtk-3.0 ./gtk-3.20 ./Makefile\" gnome-noble"
	echo "       $0 -o oomox-gnome-noble -p \"./gtk-2.0 ./gtk-3.0 ./gtk-3.20 ./Makefile\" -m gtk320 gnome-noble"
	exit 1
}


while [[ $# > 0 ]]
do
	case ${1} in
		-p|--path-list)
			CUSTOM_PATHLIST="${2}"
			shift
		;;
		-o|--output)
			OUTPUT_THEME_NAME="${2}"
			shift
		;;
		-m|--make-opts)
			MAKE_OPTS="${2}"
			shift
		;;
		*)
			if [[ "${1}" == -* ]] || [[ ${THEME-} ]]; then
				echo "unknown option ${1}"
				print_usage
				exit 2
			fi
			THEME="${1}"
		;;
	esac
	shift
done

if [[ -z "${THEME:-}" ]] ; then
	print_usage
fi

PATHLIST=(
	'./openbox-3/'
	'./gtk-2.0/'
	'./gtk-3.0/'
	'./gtk-3.20/'
	'./xfwm4/'
	'./metacity-1/'
	'./unity/'
	'Makefile'
	'index.theme'
)
if [ ! -z "${CUSTOM_PATHLIST:-}" ] ; then
	IFS=', ' read -r -a PATHLIST <<< "${CUSTOM_PATHLIST:-}"
fi

MAKE_GTK3=0
for FILEPATH in "${PATHLIST[@]}"; do
	if [[ ${FILEPATH} == *Makefile* ]] ;then
		MAKE_GTK3=1
	fi
done
MAKE_OPTS="${MAKE_OPTS-all}"

if [[ ${THEME} == */* ]] || [[ ${THEME} == *.* ]] ; then
	source "$THEME"
	THEME=$(basename ${THEME})
else
	source "$SRC_PATH/colors/$THEME"
fi
HDR_BTN_BG=${HDR_BTN_BG-$BTN_BG}
HDR_BTN_FG=${HDR_BTN_FG-$BTN_FG}

GTK3_GENERATE_DARK=$(echo ${GTK3_GENERATE_DARK-True} | tr '[:upper:]' '[:lower:]')
GTK2_HIDPI=$(echo ${GTK2_HIDPI-False} | tr '[:upper:]' '[:lower:]')

SPACING=${SPACING-3}
GRADIENT=${GRADIENT-0}
ROUNDNESS=${ROUNDNESS-2}
ROUNDNESS_GTK2_HIDPI=$(( ${ROUNDNESS} * 2 ))

OUTPUT_THEME_NAME="${OUTPUT_THEME_NAME-oomox-$THEME}"
DEST_PATH="$HOME/.themes/${OUTPUT_THEME_NAME/\//-}"

test "$SRC_PATH" = "$DEST_PATH" && echo "can't do that" && exit 1


rm -r "$DEST_PATH" || true
mkdir -p "$DEST_PATH"
cp -r "$SRC_PATH/index.theme" "$DEST_PATH"
for FILEPATH in "${PATHLIST[@]}"; do
	cp -r "$SRC_PATH/$FILEPATH" "$DEST_PATH"
done


cd "$DEST_PATH"
for FILEPATH in "${PATHLIST[@]}"; do
	find $FILEPATH -type f -exec sed -i \
		-e 's/%BG%/'"$BG"'/g' \
		-e 's/%FG%/'"$FG"'/g' \
		-e 's/%SEL_BG%/'"$SEL_BG"'/g' \
		-e 's/%SEL_FG%/'"$SEL_FG"'/g' \
		-e 's/%TXT_BG%/'"$TXT_BG"'/g' \
		-e 's/%TXT_FG%/'"$TXT_FG"'/g' \
		-e 's/%MENU_BG%/'"$MENU_BG"'/g' \
		-e 's/%MENU_FG%/'"$MENU_FG"'/g' \
		-e 's/%BTN_BG%/'"$BTN_BG"'/g' \
		-e 's/%BTN_FG%/'"$BTN_FG"'/g' \
		-e 's/%HDR_BTN_BG%/'"$HDR_BTN_BG"'/g' \
		-e 's/%HDR_BTN_FG%/'"$HDR_BTN_FG"'/g' \
		-e 's/%ROUNDNESS%/'"$ROUNDNESS"'/g' \
		-e 's/%ROUNDNESS_GTK2_HIDPI%/'"$ROUNDNESS_GTK2_HIDPI"'/g' \
		-e 's/%SPACING%/'"$SPACING"'/g' \
		-e 's/%GRADIENT%/'"$GRADIENT"'/g' \
		-e 's/%OUTPUT_THEME_NAME%/'"$OUTPUT_THEME_NAME"'/g' \
		{} \; ;
done

if [[ ${GTK3_GENERATE_DARK} != "true" ]] ; then
	cp ./gtk-3.0/scss/gtk.scss ./gtk-3.0/scss/gtk-dark.scss || true
	cp ./gtk-3.20/scss/gtk.scss ./gtk-3.20/scss/gtk-dark.scss || true
fi
if [[ ${GTK2_HIDPI} == "true" ]] ; then
	cp ./gtk-2.0/gtkrc.hidpi ./gtk-2.0/gtkrc
fi
test ${MAKE_GTK3} = 1 && make "${MAKE_OPTS}"

exit 0
