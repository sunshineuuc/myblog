@echo off
:: 删除 .deploy_git public 目录
rd /s /q .deploy_git public
del db.json
del debug.log
exit
