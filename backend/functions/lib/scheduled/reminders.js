"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.feeReminderSweep = void 0;
const scheduler_1 = require("firebase-functions/scheduler");
exports.feeReminderSweep = (0, scheduler_1.onSchedule)("every day 08:00", async () => {
    return;
});
