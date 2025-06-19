import { useState, useEffect } from "react";
import axios from "axios";
import { Container, Button, Alert, Spinner } from "react-bootstrap";
import { useSearchParams } from "react-router-dom";
const frontendUrl = import.meta.env.VITE_CLIENT_BASE_URL;
const apiBaseUrl = import.meta.env.VITE_API_BASE_URL;

function ResendSetupLink() {
  const [message, setMessage] = useState("");
  const [oldToken, setOldToken] = useState(""); // Store old token
  const [messageType, setMessageType] = useState("info"); // 'info' for success, 'danger' for errors
  const [searchParams] = useSearchParams();
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    document.title = "Password Setup Link Expired";
    const tokenFromUrl = searchParams.get("token"); // Get token from query params
    console.log("[DEBUG] Extracted Token:", tokenFromUrl); // Check if token is found
    setOldToken(tokenFromUrl || ""); // Set the old token
  }, [searchParams]);

  const handleResend = async () => {
    console.log('[DEBUG] Button clicked, token:', oldToken); // Check if token exists
    if (!oldToken) {
      console.log('[DEBUG] Missing token block reached');
      setMessage("Token is required to resend the link.");
      setMessageType("danger");
      return;
    }
    console.log('[DEBUG] Making API call...');
    setLoading(true);
    setMessage("");

    try {
      const response = await axios.get(`${apiBaseUrl}/api/auth/resend-pwd-setup?oldToken=${oldToken}`);
      console.log('[DEBUG] Full API Response:', response); // log full response
      console.log('[DEBUG] API Response Data:', response.data);
        // Handle standardized response format

      if (response.data.status === "success") {
        console.log('[DEBUG] Success case reached', response.data.newToken);
        setOldToken(response.data.newToken); // store new token
        setMessage("New link sent successfully! This window will close automatically...");
        setMessageType("success");
        setTimeout(() => window.close(), 4000);

      } else if (response.data.status === "already_set") {
        console.log('[DEBUG] Already set case reached');
        setMessage("Password already set. You may close this window.");
        setMessageType("info");
        setTimeout(() => window.close(), 4000);  // Close window after 4 seconds
      } else {
        console.log('[DEBUG] Error case reached');
        setMessage(response.data.error || "Link resend failed");
        setMessageType("danger");
      }
    } catch (error) {
      console.error('[DEBUG] API Error:', error);
      console.log('[DEBUG] Error response data:', error.response?.data);
      setMessage(error.response?.data?.error || "Failed to resend link. Please try again later.");
      setMessageType("danger");
    } finally {
      console.log('[DEBUG] Final cleanup');
      setLoading(false);
    }
  };

  return (
    <div
      className="d-flex justify-content-center align-items-center"
      style={{
        minHeight: '100vh',
        width: '100%',
        backgroundColor: '#f8f9fa'
      }}
    >
      <Container
        className="text-center p-4 shadow rounded bg-white"
        style={{
          maxWidth: "500px",
          width: "100%",
          margin: '0 20px'
        }}
      >
        <h4 className="mb-3">Password Setup Link Expired</h4>

        {message ? (
          <Alert variant={messageType} className="mb-3">
            {message}
          </Alert>
        ) : (
          <p className="mb-3">Your link has expired. Request a new one below.</p>
        )}
        
        {(messageType === "danger" || !message) && (
          <Button
            onClick={handleResend}
            disabled={loading || !oldToken}
            style={{ minWidth: '200px' }}
          >
            {loading ? (
              <>
                <Spinner as="span" size="sm" animation="border" className="me-2" />
                Sending...
              </>
            ) : "Request New Link"}
          </Button>
        )}
      </Container>
    </div>
  );}

export default ResendSetupLink;
