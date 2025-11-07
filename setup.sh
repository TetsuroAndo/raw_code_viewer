#!/bin/bash

# raw_code_viewer.shへの絶対パスを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_SCRIPT="$SCRIPT_DIR/raw_code_viewer.sh"

# ターゲットスクリプトが存在するか確認
if [[ ! -f "$TARGET_SCRIPT" ]]; then
	echo "Error: Target script not found: $TARGET_SCRIPT"
	exit 1
fi

# シンボリックリンクの名前
LINK_NAME="rawcode"

# PATHからbinディレクトリを探す
BIN_DIRS=(
	"$HOME/bin"
	"$HOME/.local/bin"
)

# PATHに含まれているディレクトリを確認
IFS=':' read -ra PATH_ARRAY <<< "$PATH"
for dir in "${PATH_ARRAY[@]}"; do
	# ユーザーのホームディレクトリ配下のbinディレクトリを優先
	if [[ "$dir" == "$HOME"* ]] && [[ -d "$dir" ]]; then
		BIN_DIRS+=("$dir")
	fi
done

# 適切なbinディレクトリを見つける
BIN_DIR=""
for dir in "${BIN_DIRS[@]}"; do
	if [[ -d "$dir" ]]; then
		BIN_DIR="$dir"
		break
	fi
done

# binディレクトリが見つからない場合はエラーで終了
if [[ -z "$BIN_DIR" ]]; then
	echo "Error: No bin directory found in PATH."
	echo "Please create one of the following directories and add it to your PATH:"
	echo "  - $HOME/bin"
	echo "  - $HOME/.local/bin"
	echo ""
	echo "Or add an existing bin directory to your PATH in ~/.zshrc or ~/.bashrc:"
	echo "  export PATH=\"\$HOME/bin:\$PATH\""
	exit 1
fi

# シンボリックリンクのフルパス
LINK_PATH="$BIN_DIR/$LINK_NAME"

# 既存のシンボリックリンクまたはファイルが存在する場合は確認
if [[ -e "$LINK_PATH" ]]; then
	if [[ -L "$LINK_PATH" ]]; then
		EXISTING_TARGET="$(readlink "$LINK_PATH")"
		if [[ "$EXISTING_TARGET" == "$TARGET_SCRIPT" ]]; then
			echo "Symbolic link already exists: $LINK_PATH -> $TARGET_SCRIPT"
			exit 0
		else
			echo "Warning: $LINK_PATH already exists and points to: $EXISTING_TARGET"
			read -p "Overwrite? (y/N): " -n 1 -r
			echo
			if [[ ! $REPLY =~ ^[Yy]$ ]]; then
				echo "Aborted."
				exit 1
			fi
			rm "$LINK_PATH"
		fi
	else
		echo "Warning: $LINK_PATH already exists and is not a symbolic link."
		read -p "Overwrite? (y/N): " -n 1 -r
		echo
		if [[ ! $REPLY =~ ^[Yy]$ ]]; then
			echo "Aborted."
			exit 1
		fi
		rm "$LINK_PATH"
	fi
fi

# シンボリックリンクを作成
ln -s "$TARGET_SCRIPT" "$LINK_PATH"

if [[ $? -eq 0 ]]; then
	echo "Successfully created symbolic link: $LINK_PATH -> $TARGET_SCRIPT"
	echo "You can now use 'rawcode' command from anywhere."
else
	echo "Error: Failed to create symbolic link."
	exit 1
fi
