# https://github.com/paradigm/dotfiles/blob/master/.zshrc
#
# ==============================================================================
# = functions_and_zle_widgets                                                  =
# ==============================================================================
#
# ------------------------------------------------------------------------------
# - zle_widgets                                                                -
# ------------------------------------------------------------------------------
#
# The ZLE widges are all followed by "zle -<MODE> <NAME>" and bound below in
# the "Key Bindings" section.

# Prepend "sudo" to the command line if it is not already there.
prepend-sudo() {
  if ! echo "$BUFFER" | grep -q "^sudo "
  then
    BUFFER="sudo $BUFFER"
    CURSOR+=5
  fi
}
zle -N prepend-sudo

# Prepend "vim" to the command line if it is not already there.
prepend-vim() {
  if ! echo "$BUFFER" | grep -q "^vim "
  then
    BUFFER="vim $BUFFER"
    CURSOR+=5
  fi
}
zle -N prepend-vim

# Delete all characters between a pair of characters.  Mimics Vim's "di" text
# object functionality.
delete-in() {
  # Create locally-scoped variables we'll need
  local CHAR LCHAR RCHAR LSEARCH RSEARCH COUNT
  # Read the character to indicate which text object we're deleting.
  read -k CHAR
  if [ "$CHAR" = "w" ]
  then # diw, delete the word.
    # find the beginning of the word under the cursor
    zle vi-backward-word
    # set the left side of the delete region at this point
    LSEARCH=$CURSOR
    # find the end of the word under the cursor
    zle vi-forward-word
    # set the right side of the delete region at this point
    RSEARCH=$CURSOR
    # Set the BUFFER to everything except the word we are removing.
    RBUFFER="$BUFFER[$RSEARCH+1,${#BUFFER}]"
    LBUFFER="$LBUFFER[1,$LSEARCH]"
    return
    # diw was unique.  For everything else, we just have to define the
    # characters to the left and right of the cursor to be removed
  elif [ "$CHAR" = "(" ] || [ "$CHAR" = ")" ]
  then # di), delete inside of a pair of parenthesis
    LCHAR="("
    RCHAR=")"
  elif [ "$CHAR" = "[" ] || [ "$CHAR" = "]" ]
  then # di], delete inside of a pair of square brackets
    LCHAR="["
    RCHAR="]"
  elif [ $CHAR = "{" ] || [ $CHAR = "}" ]
  then # di], delete inside of a pair of braces
    LCHAR="{"
    RCHAR="}"
  else
    # The character entered does not have a special definition.
    # Simply find the first instance to the left and right of the
    # cursor.
    LCHAR="$CHAR"
    RCHAR="$CHAR"
  fi
  # Find the first instance of LCHAR to the left of the cursor and the
  # first instance of RCHAR to the right of the cursor, and remove
  # everything in between.
  # Begin the search for the left-sided character directly the left of the cursor.
  LSEARCH=${#LBUFFER}
  # Keep going left until we find the character or hit the beginning of the buffer.
  while [ "$LSEARCH" -gt 0 ] && [ "$LBUFFER[$LSEARCH]" != "$LCHAR" ]
  do
    LSEARCH=$(expr $LSEARCH - 1)
  done
  # If we hit the beginning of the command line without finding the character, abort.
  if [ "$LBUFFER[$LSEARCH]" != "$LCHAR" ]
  then
    return
  fi
  # start the search directly to the right of the cursor
  RSEARCH=0
  # Keep going right until we find the character or hit the end of the buffer.
  while [ "$RSEARCH" -lt $(expr ${#RBUFFER} + 1 ) ] && [ "$RBUFFER[$RSEARCH]" != "$RCHAR" ]
  do
    RSEARCH=$(expr $RSEARCH + 1)
  done
  # If we hit the end of the command line without finding the character, abort.
  if [ "$RBUFFER[$RSEARCH]" != "$RCHAR" ]
  then
    return
  fi
  # Set the BUFFER to everything except the text we are removing.
  RBUFFER="$RBUFFER[$RSEARCH,${#RBUFFER}]"
  LBUFFER="$LBUFFER[1,$LSEARCH]"
}
zle -N delete-in


# Delete all characters between a pair of characters and then go to insert mode.
# Mimics Vim's "ci" text object functionality.
change-in() {
  zle delete-in
  zle vi-insert
}
zle -N change-in

# Delete all characters between a pair of characters as well as the surrounding
# characters themselves.  Mimics Vim's "da" text object functionality.
delete-around() {
  zle delete-in
  zle vi-backward-char
  zle vi-delete-char
  zle vi-delete-char
}
zle -N delete-around

# Delete all characters between a pair of characters as well as the surrounding
# characters themselves and then go into insert mode  Mimics Vim's "ca" text
# object functionality.
change-around() {
  zle delete-in
  zle vi-backward-char
  zle vi-delete-char
  zle vi-delete-char
  zle vi-insert
}
zle -N change-around

# Increment the number under the cursor, or find the next number to the right
# of the cursor and increment that number.  Emulate vim's ctrl-a functionality.
# This code is not my style at all; presumably I found it somewhere online, but
# I no longer remember the source to cite or credit.
increment-number() {
  emulate -L zsh
  setopt extendedglob
  local pos num newnum sign buf
  if [[ $BUFFER[$((CURSOR + 1))] = [0-9] ]]; then
    pos=$((${#LBUFFER%%[0-9]##} + 1))
  else
    pos=$(($CURSOR + ${#RBUFFER%%[0-9]*} + 1))
  fi
  (($pos <= ${#BUFFER})) || return
  num=${${BUFFER[$pos,-1]}%%[^0-9]*}
  if ((pos > 0)) && [[ $BUFFER[$((pos - 1))] = '-' ]]; then
    num=$((0 - num))
    ((pos--))
  fi
  newnum=$((num + ${NUMERIC:-${incarg:-1}}))
  if ((pos > 1)); then
    buf=${BUFFER[0,$((pos - 1))]}${BUFFER[$pos,-1]/$num/$newnum}
  else
    buf=${BUFFER/$num/$newnum}
  fi
  BUFFER=$buf
  CURSOR=$((pos + $#newnum - 2))
}
zle -N increment-number

# Decrement the number under the cursor, or find the next number to the right
# of the cursor and increment that number.  Emulate vim's ctrl-x functionality.
# This code is not my style at all; presumably I found it somewhere online, but
# I no longer remember the source to cite or credit.
decrement-number() {
  emulate -L zsh
  setopt extendedglob
  local pos num newnum sign buf
  if [[ $BUFFER[$((CURSOR + 1))] = [0-9] ]]; then
    pos=$((${#LBUFFER%%[0-9]##} + 1))
  else
    pos=$(($CURSOR + ${#RBUFFER%%[0-9]*} + 1))
  fi
  (($pos <= ${#BUFFER})) || return
  num=${${BUFFER[$pos,-1]}%%[^0-9]*}
  if ((pos > 0)) && [[ $BUFFER[$((pos - 1))] = '-' ]]; then
    num=$((0 - num))
    ((pos--))
  fi
  newnum=$((num - ${NUMERIC:-${incarg:-1}}))
  if ((pos > 1)); then
    buf=${BUFFER[0,$((pos - 1))]}${BUFFER[$pos,-1]/$num/$newnum}
  else
    buf=${BUFFER/$num/$newnum}
  fi
  BUFFER=$buf
  CURSOR=$((pos + $#newnum - 2))
}
zle -N decrement-number

# Zsh's history-beginning-search-backward is very close to Vim's
# i_ctrl-x_ctrl-l; however, with Vim, it leaves you in insert mode with the
# cursor at the end of the line.  Surprisingly, there was nothing closer to Vim
# in Zsh by default.  This creates something closer to Vim's i_ctrl-x_ctrl-l.
history-beginning-search-backward-then-append() {
  zle history-beginning-search-backward
  zle vi-add-eol
}
zle -N history-beginning-search-backward-then-append

# ------------------------------------------------------------------------------
# - non-zle_widget_functions                                                   -
# ------------------------------------------------------------------------------

# Change directory then immediately clear the screen and run `ls`.
cds() {
  cd $1 && clear && ls
}

# ==============================================================================
# = key_bindings                                                               =
# ==============================================================================
#
# My goal here is to make the ZLE feel as much like Vim as possible without
# losing any useful functionality.

# Remove escape timeout in insert mode
#bindkey -rpM viins '^['

# Remove escape timeout in normal mode
#bindkey -rpM vicmd '^['

# ------------------------------------------------------------------------------
# - insert_mode_(key bindings)                                                 -
# ------------------------------------------------------------------------------

# Have i_backspace work as it does in Vim.
bindkey -M viins "^?" backward-delete-char

# Have i_ctrl-a work as it does in Vim.
bindkey -M viins "^A" beginning-of-line

# Have i_ctrl-e work as it does in Vim.
bindkey -M viins "^E" end-of-line

# Have i_ctrl-p work as c_ctrl-p does in Vim.
bindkey -M viins "^P" up-line-or-history

# Have i_ctrl-n work as c_ctrl-n does in Vim.
bindkey -M viins "^N" down-line-or-history

# Have i_ctrl-h work as it does in Vim.
bindkey -M viins "^H" backward-delete-char

# Have i_ctrl-b work as i_ctrl-p does in Vim.
bindkey -M viins "^B" _history-complete-newer

# Have i_ctrl-f work as i_ctrl-n does in Vim.
bindkey -M viins "^F" _history-complete-older

# Prepend "sudo ".  This does not have a Vim parallel.
bindkey "^S" prepend-sudo

# Prepend "vim ".  This does not have a Vim parallel.
bindkey "^V" prepend-vim

# Have i_ctrl-u work as it does in Vim.
bindkey -M viins "^U" backward-kill-line

# Have i_ctrl-w work as it does in Vim.
bindkey -M viins "^W" backward-kill-word

# Have i_ctrl-x_i_ctrl-l work as it does in Vim.
bindkey -M viins "^X^L" history-beginning-search-backward-then-append

# Display _completion_help for creating completion functions.  This does not
# have a Vim parallel.
bindkey -M viins "^X^H" _complete_help

# attempt to complete line based on history, roughly as i_ctrl-x_ctrl-l does in
# Vim.
bindkey -M viins "^X^L" history-incremental-search-backward

# Cut the contents of the line and paste immediately when the next prompt
# appears.  This does not have a clean Vim parallel.
bindkey -M viins "^Y" push-line

# ------------------------------------------------------------------------------
# - normal_mode_(key_bindings)                                                 -
# ------------------------------------------------------------------------------

# Have ctrl-a work as it does in Vim.
bindkey -M vicmd "^A" increment-number

# Mimics Vim's "ca" text object functionality.
bindkey -M vicmd "ca" change-around

# Mimics Vim's "ci" text object functionality.
bindkey -M vicmd "ci" change-in

# Mimic Vim's da text-object functionality.
bindkey -M vicmd "da" delete-around

# Mimic Vim's di text-object functionality.
bindkey -M vicmd "di" delete-in

# Have ctrl-e work as it does in Vim.
bindkey -M vicmd "^E" vi-add-eol

# Have g~ work as it does in Vim.
bindkey -M vicmd "g~" vi-oper-swap-case

# Have ga work as it does in Vim.
bindkey -M vicmd "ga" what-cursor-position

# Have gg work as it does in Vim.
bindkey -M vicmd "gg" beginning-of-history

# Have G work as it does in Vim.
bindkey -M vicmd "G" end-of-history

# Have ctrl-r work as it does in Vim.
bindkey -M vicmd "^R" redo

# Editing the line in Vim proper.
autoload edit-command-line
zle -N edit-command-line
bindkey -M vicmd "^V" edit-command-line
bindkey -M vicmd v edit-command-line

# Have ctrl-x work as it does in Vim.
bindkey -M vicmd "^X" decrement-number
