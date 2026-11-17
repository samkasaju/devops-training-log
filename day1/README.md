# Day 1 – Linux Disk Space Investigation

## 1. Lab Objective

Investigate disk usage on Ubuntu, identify deleted files still held open by processes, understand the difference between `df` and `du`, and create a disk monitoring script.

## 2. Create Log Files

Created five 30 MB log files:

```bash
mkdir -p ~/lab/day1/var/log/app
cd ~/lab/day1/var/log/app

for i in {1..5}; do
    dd if=/dev/urandom of=app-$i.log bs=1M count=30
done
```

## 3. Simulate a Deleted-but-Open File

Created a 200 MB file and opened it with `tail`:

```bash
head -c 200M /dev/zero > held.log
tail -f held.log > /dev/null &
rm held.log
```

The file disappeared from the directory, but its disk space remained allocated because the `tail` process still had it open.

## 4. Investigate Disk Usage

Commands used:

```bash
du -ah . | sort -rh | head -n 5
find . -type f -exec du -h {} + | sort -rh | head -n 5
sudo lsof +L1
```

The `lsof +L1` command helped identify deleted files still held open by processes.

## 5. Difference Between df and du

- `df` reports filesystem-level disk usage, including space occupied by deleted files that are still open.
- `du` reports disk usage of files and directories that are currently accessible through directory entries.

This explains why `df` can report more used space than `du`.

## 6. Release the Disk Space

Identified the lab's `tail` processes and stopped them:

```bash
kill 68515 68526
sudo lsof +L1 | grep held.log
df -h .
```

After the processes closed their file descriptors, the deleted file's space could be released.

## 7. Disk Monitoring Script

The `disk-check.sh` script:

- Accepts a directory path and usage threshold.
- Checks filesystem usage with `df`.
- Prints the top five largest directories when usage exceeds the threshold.
- Exits with status `1` when usage is above the threshold.
- Exits with status `0` when usage is within the threshold.
- Exits with status `2` for invalid input.

### Test Results

| Test | Expected result | Actual result |
|---|---|---|
| `./disk-check.sh . 80` | Usage within threshold; exit 0 | Passed |
| `./disk-check.sh . 70` | Warning; exit 1 | Passed |
| Missing arguments | Error; exit 2 | Passed |
| Invalid directory | Error; exit 2 | Passed |
| Non-numeric threshold | Error; exit 2 | Passed |
| Threshold above 100 | Error; exit 2 | Passed |

## 8. DevOps Questions

### Q1. What happens when a pipeline stage fails?

A pipeline should detect the failure and follow its configured failure policy. Usually, dependent stages stop, and the failure is reported so it can be investigated.

### Q2. What is the difference between liveness and readiness probes?

- Liveness checks whether a container is still running properly and should be restarted if unhealthy.
- Readiness checks whether a container is ready to receive traffic.

### Q3. What are Terraform plan and state?

- `terraform plan` previews the infrastructure changes Terraform intends to make.
- Terraform state records the infrastructure resources managed by Terraform and their tracked attributes.

### Q4. What would you do in the first 10 minutes after an alert reports a 40% error rate?

1. Acknowledge the alert and check its scope.
2. Check dashboards, logs, and recent deployments.
3. Identify affected services and users.
4. Check infrastructure health and dependencies.
5. Roll back a recent change or mitigate the issue if appropriate.
6. Communicate the incident and continue monitoring.

## 9. Interview Question

**Developer says disk full but `du` shows only 40% used. What's happening?**

A deleted file may still be held open by a running process, so `du` cannot see it but `df` still counts its allocated disk blocks. I would investigate with `lsof +L1` and identify the process holding the file. After safely closing or restarting that process, the space should be released.

## 10. Key Learning

Linux disk usage must be investigated at both the filesystem and directory levels. Deleted-but-open files can consume disk space even when they are no longer visible in a directory.
