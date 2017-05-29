# this is stupid, but sometimes something deletes the files from priv/templates
# this script is to recover it
for x in `git status|grep deleted|awk '{print $2}'` 
do
  git checkout -- $x
done
