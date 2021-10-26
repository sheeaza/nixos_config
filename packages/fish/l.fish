function l --wraps='ls --group-directories-first' --description 'alias l=ls --group-directories-first'
  ls --group-directories-first $argv; 
end
