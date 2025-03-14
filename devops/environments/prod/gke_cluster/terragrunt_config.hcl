# 禁用状态锁
disable_init_lock = true

# 启用重试机制
retryable_errors = [
  "(?s).*Error acquiring the state lock.*",
  "(?s).*timeout while waiting for state to become unlocked.*",
  "(?s).*is already locked.*",
  "(?s).*TLS handshake timeout.*",
  "(?s).*connection reset by peer.*"
]

retry_max_attempts = 5
retry_sleep_interval_sec = 30
