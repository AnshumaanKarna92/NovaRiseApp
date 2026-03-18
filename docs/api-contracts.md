# API Contracts

## Callable functions

- `createOrUpdateFeeReceipt`
- `verifyFeePayment`
- `recordCashPayment`
- `submitAttendance`
- `updateAttendance`
- `publishNotice`
- `createClassMessage`
- `getDashboardSummaries`

## Import pipeline

- `importStudentsCsv` is exposed as an HTTP function
- It creates an `import_jobs` document and returns a job id
