require "init.type"
require "init.component"
require "init.system"

local pipeline = require "register.pipeline"
pipeline "update"
    .stage "update"
pipeline "clean"
    .stage "clean"
pipeline "build"
    .stage "init"
    .stage "build"
pipeline "backup"
    .stage "backup_start"
    .stage "backup"
    .stage "backup_finish"
pipeline "restore"
    .stage "restore_start"
    .stage "restore"
    .stage "restore_finish"
pipeline "prototype"
    .stage "prototype_restore"
