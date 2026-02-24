---| sqlite - audit log table


---| Create tabel audit log untuk record semua anomali data
CREATE TABLE IF NOT EXISTS audit_log (
    log_id INTEGER PRIMARY KEY,
    logged_at DATETIME DEFAULT (DATETIME(CURRENT_TIMESTAMP, '+7 hours')),
    row_id INTEGER,
    attribute TEXT,
    reason TEXT,
    solution TEXT,
    source_table TEXT,
    total_rows INTEGER,
    status_log TEXT,
    UNIQUE(row_id, attribute, reason, solution, source_table, total_rows) );


--- checking newest unique records of audit_log max 100 rows (unique without log_id, row_id, logged_at)
SELECT DISTINCT
    attribute, reason, solution, source_table, total_rows, status_log 
FROM audit_log 
ORDER BY logged_at DESC;


--- checking the latest record date-time in audit_log table
SELECT DISTINCT logged_at
FROM audit_log 
ORDER BY logged_at DESC;



---| Create tabel BACKUP audit log untuk backup semua record di audit log 
CREATE TABLE IF NOT EXISTS BACKUP_audit_log (
    log_id INTEGER PRIMARY KEY,
    logged_at DATETIME DEFAULT (DATETIME(CURRENT_TIMESTAMP, '+7 hours')),
    row_id INTEGER,
    attribute TEXT,
    reason TEXT,
    solution TEXT,
    source_table TEXT,
    total_rows INTEGER,
    status_log TEXT,
    UNIQUE(row_id, attribute, reason, solution, source_table, total_rows) );



---| CREATE Trigger for automate input ke BACKUP_audit_log table
---| Trigger activated after every INSERT on the audit_log table 
CREATE TRIGGER trigger_insert_to_BACKUP_audit_log
AFTER INSERT ON audit_log
BEGIN
    INSERT INTO BACKUP_audit_log (
        log_id,
        logged_at,
        row_id,
        attribute,
        reason,
        solution,
        source_table,
        total_rows,
        status_log)
    VALUES (
        NEW.log_id,
        NEW.logged_at,
        NEW.row_id,
        NEW.attribute,
        NEW.reason,
        NEW.solution,
        NEW.source_table,
        NEW.total_rows,
        NEW.status_log);
END;