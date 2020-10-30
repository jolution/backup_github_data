# backup data/github
Backup Script for GitHub Branches

# Install
* Download files/folder in /backup on your backup server
* After testing, insert the following cron-jobs with `Crontab -e` or https://console.cron-job.org/login (not mine)

## keep one daily check (At 03:00)
0 3   *   *   *   /backup/backup_data.sh
