import RNHTMLtoPDF from 'react-native-html-to-pdf';

export async function generateCaregiverReport(html) {
  let options = { html, fileName: 'caregiver_report', directory: 'Documents' };
  return await RNHTMLtoPDF.convert(options);
}
