# Cần refactor emailService.js sang SendGrid

File hiện tại còn code Brevo cũ. Cần thay thế các function sau bằng SendGrid:

## Functions cần fix:

1. **sendEmail()** - line 228-269
2. **testEmailService()** - line 427-462

## SendGrid API format:

```javascript
const msg = {
  to: email,
  from: "ZBudget <noreply@sendgrid.net>",
  subject: template.subject,
  html: template.html,
  text: template.text,
};

await sgMail.send(msg);
```

## Environment variables:

- `SENDGRID_API_KEY`
- `SENDGRID_FROM_EMAIL` (optional)
