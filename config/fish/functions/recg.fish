function recg --description "Toggle region screen recording"
    rec --stop; and return
    set geometry (slurp); or return
    rec -g $geometry $argv
end
