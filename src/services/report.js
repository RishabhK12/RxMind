import { generateCaregiverReport } from './pdf';

// Generate PDF report for caregiver
export async function createCaregiverReport({
  user,
  complianceHistory,
  flaggedTasks,
  missedTasks,
}) {
  // Build HTML for the report
  const html = `
    <h1>RxMind Caregiver Report</h1>
    <h2>Patient Info</h2>
    <ul>
      <li>Weight: ${user.weight}</li>
      <li>Height: ${user.height}</li>
      <li>Sleep Schedule: ${user.sleepSchedule}</li>
      <li>Eating Times: ${user.eatingTimes}</li>
      <li>Baseline BP: ${user.baselineBP}</li>
      <li>Discharge Uploaded: ${user.dischargeUploaded ? 'Yes' : 'No'}</li>
    </ul>
    <h2>Daily Compliance</h2>
    <ul>
      ${complianceHistory
        .map(
          day =>
            `<li>${day.date}: ${day.completed}/${day.total} completed, ${
              day.missed
            } missed (${day.percent.toFixed(1)}%)</li>`,
        )
        .join('')}
    </ul>
    <h2>Flagged Tasks</h2>
    <ul>
      ${flaggedTasks
        .map(t => `<li>${t.title} at ${t.time} - ${t.description || ''}</li>`)
        .join('')}
    </ul>
    <h2>Missed Tasks</h2>
    <ul>
      ${missedTasks
        .map(t => `<li>Task ID: ${t.taskId} at ${t.timestamp}</li>`)
        .join('')}
    </ul>
    <h2>Summary</h2>
    <p>Overall completion rate: ${
      complianceHistory.length
        ? (
            complianceHistory.reduce((sum, d) => sum + d.percent, 0) /
            complianceHistory.length
          ).toFixed(1)
        : 0
    }%</p>
  `;
  return await generateCaregiverReport(html);
}
