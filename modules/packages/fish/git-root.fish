function git-root --wraps='cd (git rev-parse --show-toplevel)' --description 'alias git-root=cd (git rev-parse --show-toplevel)'
  cd (git rev-parse --show-toplevel) $argv; 
end
