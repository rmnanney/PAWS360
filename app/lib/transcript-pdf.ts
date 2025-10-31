// Lightweight PDF generator for transcripts using jsPDF + autotable
// Generates a printable academic transcript PDF on the client.

type TranscriptCourse = {
  courseCode: string;
  title: string;
  grade: string;
  credits: number;
};

type TranscriptTerm = {
  termLabel: string;
  gpa: number | null;
  credits: number | null;
  courses: TranscriptCourse[];
};

type TranscriptResponse = {
  terms: TranscriptTerm[];
};

async function loadImageDataUrl(url: string): Promise<string | null> {
  return new Promise((resolve) => {
    try {
      const img = new Image();
      img.crossOrigin = 'anonymous';
      img.onload = () => {
        try {
          const canvas = document.createElement('canvas');
          canvas.width = img.width;
          canvas.height = img.height;
          const ctx = canvas.getContext('2d');
          if (!ctx) return resolve(null);
          ctx.drawImage(img, 0, 0);
          const dataUrl = canvas.toDataURL('image/png');
          resolve(dataUrl);
        } catch {
          resolve(null);
        }
      };
      img.onerror = () => resolve(null);
      img.src = url;
    } catch {
      resolve(null);
    }
  });
}

export async function generateTranscriptPdf(opts: {
  universityName?: string;
  student: any; // UserResponseDTO
  studentId: number;
  summary: any; // AcademicSummaryResponseDTO
  transcript: TranscriptResponse;
  program?: { code?: string | null; name?: string | null; department?: string | null; totalCreditsRequired?: number | null } | null;
  advisor?: { name?: string | null; email?: string | null; phone?: string | null } | null;
}) {
  const { default: jsPDF } = await import('jspdf');
  await import('jspdf-autotable');

  const doc = new jsPDF({ unit: 'pt', format: 'letter' });
  const margin = 48;
  let y = margin;

  const uni = opts.universityName || 'University of Wisconsin, Milwaukee';
  const s = opts.student || {};
  const sum = opts.summary || {};
  const prog = opts.program || {};

  const fullName = [s.firstname, s.lastname].filter(Boolean).join(' ');
  const dob = s.dob ? new Date(s.dob).toLocaleDateString() : '-';

  // Header + seal
  const logoDataUrl = await loadImageDataUrl('/uwmLogo.png');
  doc.setFont('times', 'bold');
  doc.setFontSize(18);
  doc.text(uni, margin, y);
  if (logoDataUrl) {
    try {
      // Place logo at top-right
      const imgW = 64, imgH = 64;
      doc.addImage(logoDataUrl, 'PNG', 612 - margin - imgW, y - 14, imgW, imgH);
    } catch {}
  }
  y += 24;
  doc.setFontSize(14);
  doc.text('Official Academic Transcript', margin, y);
  y += 10;
  doc.setDrawColor(0);
  doc.setLineWidth(0.5);
  doc.line(margin, y, 612 - margin, y);
  y += 16;

  // Student block
  doc.setFont('times', 'bold');
  doc.setFontSize(12);
  doc.text('Student Information', margin, y);
  y += 14;
  doc.setFont('times', 'normal');

  const kv = (label: string, value: any) => `${label}: ${value ?? '-'}`;

  // Address formatting (prefer MAILING, then HOME, then first)
  const addresses: any[] = Array.isArray(s.addresses) ? s.addresses : [];
  function pickAddress(list: any[]): any | null {
    if (!list || list.length === 0) return null;
    const byType = (t: string) => list.find(a => (a.address_type || '').toUpperCase() === t);
    return byType('MAILING') || byType('HOME') || list[0];
  }
  function formatAddress(a: any | null): string[] {
    if (!a) return ['-'];
    const lines: string[] = [];
    if (a.street_address_1) lines.push(String(a.street_address_1));
    if (a.street_address_2) lines.push(String(a.street_address_2));
    const cityStateZip = [a.city, a.us_states, a.zipcode].filter(Boolean).join(', ');
    if (cityStateZip) lines.push(cityStateZip);
    if (a.po_box) lines.push(`PO Box ${a.po_box}`);
    return lines.length ? lines : ['-'];
  }
  const mailing = formatAddress(pickAddress(addresses));

  const leftCol = [
    kv('Name', fullName || '-'),
    kv('Student ID', opts.studentId),
    kv('Email', s.email),
    kv('Date of Birth', dob),
  ];
  const rightCol = [
    kv('Status', s.status),
    kv('Role', s.role),
    kv('Phone', s.phone),
  ];

  leftCol.forEach((line, idx) => {
    doc.text(line, margin, y + idx * 14);
  });
  rightCol.forEach((line, idx) => {
    doc.text(line, 330, y + idx * 14);
  });
  y += Math.max(leftCol.length, rightCol.length) * 14 + 12;

  // Mailing address block
  doc.setFont('times', 'bold');
  doc.text('Mailing Address', margin, y);
  y += 14;
  doc.setFont('times', 'normal');
  mailing.forEach((line, idx) => doc.text(line, margin, y + idx * 14));
  y += mailing.length * 14 + 12;

  // Program block
  doc.setFont('times', 'bold');
  doc.text('Program', margin, y);
  y += 14;
  doc.setFont('times', 'normal');
  const programRows = [
    [ 'Major / Program', prog?.name || '-' ],
    [ 'Program Code', prog?.code || '-' ],
    [ 'Department', prog?.department || '-' ],
    [ 'Expected Graduation', sum?.expectedGraduation ?? '-' ],
    [ 'Academic Standing', sum?.academicStanding ?? '-' ],
    [ 'Cumulative GPA', (typeof sum?.cumulativeGPA === 'number' ? sum.cumulativeGPA : '-') ],
    [ 'Total Credits Earned', (typeof sum?.totalCredits === 'number' ? sum.totalCredits : '-') ],
    [ 'Program Credits Required', (typeof prog?.totalCreditsRequired === 'number' ? prog?.totalCreditsRequired : '-') ],
  ];
  (doc as any).autoTable({
    startY: y,
    head: [['Field', 'Value']],
    body: programRows,
    theme: 'grid',
    styles: { font: 'times', fontSize: 10, cellPadding: 6 },
    headStyles: { fillColor: [30, 41, 59], textColor: 255 },
    columnStyles: { 0: { cellWidth: 180 } },
    margin: { left: margin, right: margin },
  });
  y = (doc as any).lastAutoTable.finalY + 16;

  // Advisor block (optional)
  if (opts.advisor && (opts.advisor.name || opts.advisor.email || opts.advisor.phone)) {
    doc.setFont('times', 'bold');
    doc.text('Advisor', margin, y);
    y += 14;
    doc.setFont('times', 'normal');
    const advRows = [
      ['Advisor Name', opts.advisor.name || '-'],
      ['Email', opts.advisor.email || '-'],
      ['Phone', opts.advisor.phone || '-'],
    ];
    (doc as any).autoTable({
      startY: y,
      head: [['Field', 'Value']],
      body: advRows,
      theme: 'grid',
      styles: { font: 'times', fontSize: 10, cellPadding: 6 },
      headStyles: { fillColor: [30, 41, 59], textColor: 255 },
      columnStyles: { 0: { cellWidth: 180 } },
      margin: { left: margin, right: margin },
    });
    y = (doc as any).lastAutoTable.finalY + 16;
  }

  // Transcript terms
  doc.setFont('times', 'bold');
  doc.text('Course History', margin, y);
  y += 10;

  const terms = Array.isArray(opts.transcript?.terms) ? opts.transcript.terms : [];
  for (const term of terms) {
    const head = `${term.termLabel || 'Term'}  |  GPA: ${term.gpa ?? '-'}  |  Credits: ${term.credits ?? '-'}`;
    doc.setFont('times', 'bold');
    doc.text(head, margin, y);
    y += 8;
    doc.setFont('times', 'normal');
    const body = (term.courses || []).map((c) => [c.courseCode, c.title, String(c.credits ?? 0), c.grade ?? '']);
    (doc as any).autoTable({
      startY: y,
      head: [['Course', 'Title', 'Credits', 'Grade']],
      body,
      theme: 'striped',
      styles: { font: 'times', fontSize: 10, cellPadding: 6 },
      headStyles: { fillColor: [30, 41, 59], textColor: 255 },
      columnStyles: { 0: { cellWidth: 90 }, 2: { halign: 'right', cellWidth: 60 }, 3: { halign: 'center', cellWidth: 60 } },
      margin: { left: margin, right: margin },
    });
    y = (doc as any).lastAutoTable.finalY + 14;
  }

  // Footer summary
  if (typeof sum?.cumulativeGPA === 'number' || typeof sum?.totalCredits === 'number') {
    doc.setFont('times', 'bold');
    doc.text('Summary', margin, y);
    y += 12;
    doc.setFont('times', 'normal');
    doc.text(`Cumulative GPA: ${typeof sum?.cumulativeGPA === 'number' ? sum.cumulativeGPA : '-'}`, margin, y);
    y += 14;
    doc.text(`Total Credits Earned: ${typeof sum?.totalCredits === 'number' ? sum.totalCredits : '-'}`, margin, y);
    y += 12;
  }

  // Signature lines
  const footerY = 792 - margin - 48;
  doc.setDrawColor(0);
  // Registrar signature line
  doc.line(margin, footerY, margin + 220, footerY);
  doc.setFont('times', 'normal');
  doc.setFontSize(10);
  doc.text('Registrar Signature', margin, footerY + 14);
  // Date line
  doc.line(360, footerY, 360 + 120, footerY);
  doc.text('Date', 360, footerY + 14);

  // Generated footer
  const gen = new Date().toLocaleString();
  doc.setFontSize(9);
  doc.setTextColor(100);
  doc.text(`Generated on ${gen}`, margin, 792 - margin);

  doc.save('transcript.pdf');
}
