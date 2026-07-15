// Sparrow SMS Service Simulator for Nepalese MSMEs
// Real Sparrow API Endpoint: https://api.sparrowsms.com/v2/sms/

export const sparrowSMS = {
  // Simulates sending an SMS through Sparrow SMS API
  async sendSMS(to, text, token = "MOCK_SPARROW_TOKEN_123") {
    console.log(`[Sparrow SMS] Initiating API call to Sparrow SMS Gateway...`);
    console.log(`[Sparrow SMS] POST Payload:`, {
      token: token,
      from: "SajiloKhata",
      to: to,
      text: text
    });

    // Simulate network delay
    await new Promise(resolve => setTimeout(resolve, 800));

    // Simple validation
    if (!to || to.length < 10) {
      return {
        status: "error",
        response_code: 400,
        message: "Invalid Nepalese Mobile Number. Must be 10 digits."
      };
    }

    // Mock API Success Response (matching Sparrow SMS format)
    const successResponse = {
      status: "success",
      response_code: 200,
      response: "SMS Sent Successfully.",
      credits_consumed: 1,
      total_credits: 482,
      message_id: "msg_" + Math.floor(Math.random() * 10000000),
      to: to,
      text: text
    };

    console.log(`[Sparrow SMS] API Response Received:`, successResponse);
    return successResponse;
  },

  // Generates the reminder SMS text in English or Nepali
  generateReminderText(customerName, amount, shopName = "Sajilo Khata Shop", lang = "ne") {
    if (lang === "ne") {
      return `नमस्ते ${customerName} ज्यू, तपाईंको ${shopName} मा बाँकी भुक्तानी रु. ${amount} बाँकी रहेको छ। कृपया चाँडै भुक्तानी गरिदिनुहोला। धन्यवाद!`;
    } else {
      return `Namaste ${customerName}, you have an outstanding credit balance of NPR ${amount} at ${shopName}. Please clear your dues at your earliest convenience. Thank you!`;
    }
  }
};
