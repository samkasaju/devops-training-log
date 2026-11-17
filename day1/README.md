# Day 1 – Linux Disk Space Investigation

## 1. Lab Objective

Investigate disk usage on Ubuntu, identify deleted files still held open by processes, understand the difference between `df` and `du`, and create a disk monitoring script.

## 2. Create Log Files

Created five 30 MB log files to simulate application logs:

```bash
mkdir -p ~/lab/day1/var/log/app
cd ~/lab/day1/var/log/app

for i in {1..5}; do
    dd if=/dev/urandom of=app-$i.log bs=1M count=30
done
```

Each file was approximately 30 MB.

## 3. Simulate a Deleted-but-Open File

Created a 200 MB file and opened it with `tail`:

```bash
head -c 200M /dev/zero > held.log
tail -f held.log > /dev/null &
rm held.log
```

The file disappeared from the directory, but its disk space remained allocated because the `tail` process still had it open.

## 4. Investigate Disk Usage

Commands used to identify large files and investigate disk usage:

```bash
du -ah . | sort -rh | head -n 5
find . -type f -exec du -h {} + | sort -rh | head -n 5
sudo lsof +L1
```

The `lsof +L1` command helped identify deleted files that were still held open by running processes.

The output showed the `tail` processes holding the deleted `held.log` file open.

## 5. Difference Between df and du

- `df` reports filesystem-level disk usage, including space occupied by deleted files that are still open.
- `du` reports disk usage of files and directories accessible through directory entries.

This explains why `df` can report more used space than `du`.

## 6. Release the Disk Space

Identified the processes holding the deleted file open using:

```bash
sudo lsof +L1
```

Stopped the lab's `tail` processes:

```bash
kill 68515 68526
sudo lsof +L1 | grep held.log
df -h .
```

After the processes closed their file descriptors, the deleted file's disk space could be released.

## 7. Bonus: Demonstrate df vs du with tmpfs

Created a temporary 50 MB RAM-backed filesystem:

```bash
sudo mkdir -p /mnt/tiny
sudo mount -t tmpfs -o size=50M tmpfs /mnt/tiny
sudo chown "$USER" /mnt/tiny
```

Created a 40 MB file and checked its usage:

```bash
cd /mnt/tiny
head -c 40M /dev/zero > big.log

df -h /mnt/tiny
du -sh /mnt/tiny
```

Started a process holding the file open, then deleted the file:

```bash
tail -f big.log > /dev/null &
rm big.log
```

After deletion:

- `du` reported 0 usage for the directory.
- `df` still reported approximately 40 MB used (80% of the temporary filesystem).

Found and stopped the process:

```bash
jobs -l
kill 73173
df -h /mnt/tiny
```

After the process stopped, filesystem usage returned to 0.

Cleaned up the temporary filesystem:

```bash
cd ~
sudo umount /mnt/tiny
sudo rmdir /mnt/tiny
```

This experiment demonstrated how a deleted-but-open file can consume filesystem space without appearing in directory usage.

## 8. Disk Monitoring Script

Created `disk-check.sh`, which:

- Accepts a directory path and usage threshold.
- Validates the input arguments.
- Checks filesystem usage with `df`.
- Prints the largest directory entries when usage exceeds the threshold.
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

## 9. DevOps Questions

### Q1. What happens when a pipeline stage fails?

A pipeline should detect the failure and follow its configured failure policy. Usually, dependent stages stop, and the failure is reported so it can be investigated. In Bash, `set -o pipefail` helps ensure that a pipeline reports a failure if an earlier command fails.

### Q2. What is the difference between liveness and readiness probes?

- Liveness checks whether a container is still running properly and should be restarted if unhealthy.
- Readiness checks whether a container is ready to receive traffic.

### Q3. What are Terraform plan and state?

- `terraform plan` compares the desired infrastructure configuration with the current state and observed infrastructure, then previews the proposed changes.
- Terraform state records the infrastructure resources managed by Terraform and their tracked attributes.

### Q4. What would you do in the first 10 minutes after an alert reports a 40% error rate?

1. Acknowledge the alert and check its scope.
2. Check dashboards, logs, and recent deployments.
3. Identify affected services and users.
4. Check infrastructure health and dependencies.
5. Roll back a recent change or mitigate the issue if appropriate.
6. Communicate the incident and continue monitoring.

## 10. Interview Question

**Developer says disk full but `du` shows only 40% used. What's happening?**

A deleted file may still be held open by a running process, so `du` cannot see it but `df` still counts its allocated disk blocks. I would investigate with `lsof +L1` and identify the process holding the file. After safely closing or restarting that process, the space should be released.

## 11. Key Learning

Linux disk usage must be investigated at both the filesystem and directory levels. Deleted-but-open files can consume disk space even when they are no longer visible in a directory.

This lab helped me practise Linux commands, disk troubleshooting, Bash scripting, process management, and basic DevOps problem-solving.
