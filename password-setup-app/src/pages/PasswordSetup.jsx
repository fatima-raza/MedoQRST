import { useState, useEffect } from "react";
import { useNavigate, useLocation } from "react-router-dom";
import axios from "axios";
import { Container, Form, Button, Spinner, InputGroup } from "react-bootstrap";
const frontendUrl = import.meta.env.VITE_CLIENT_BASE_URL;
const apiBaseUrl = import.meta.env.VITE_API_BASE_URL;

function PasswordSetup() {
  const location = useLocation();
  const queryParams = new URLSearchParams(location.search);
  const token = queryParams.get("token");
  const [status, setStatus] = useState("loading"); // 'loading', 'valid', 'already_set', 'invalid'
  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [message, setMessage] = useState("");
  const [loading, setLoading] = useState(false);
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);
  const navigate = useNavigate();

  useEffect(() => {
    document.title = "Set Your Password";
    if (!token) {
      setStatus("invalid");
      setMessage("Invalid or expired link. Please request a new one.");
      return;
    }
    verifyToken();
  }, [token]);

  const verifyToken = async () => {
    console.log("Received token:", token); // Log token before API call
    if (!token) {
      setStatus("invalid");
      setMessage("Invalid or expired link. Please request a new one.");
      return;
    }
    try {
      console.log("Verifying token:", token); // Debugging: Check if token is correct
      const response = await axios.get(`${apiBaseUrl}/api/auth/verify-token?token=${token}`);
      console.log("API Response:", response.data); // Log the response from backend
      setStatus(response.data.status);
      
    } catch (error) {
      console.error("Token verification failed:", error.response?.data || error.message);
      setStatus("invalid");
      setMessage("Invalid or expired link. Please request a new one.");
    }
  };

  const validatePassword = (pwd) => {
    return pwd.length >= 8 && /[A-Z]/.test(pwd) && /\d/.test(pwd);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();

    // Reset message before validation
    setMessage("");
    
    if (!validatePassword(password)) {
      setMessage("Password must be at least 8 characters, includes a number and an uppercase letter.");
      return;
    }

    if (password !== confirmPassword) {
      setMessage("Passwords do not match");
      return;
    }

    setLoading(true);

    try {
      await axios.post(`${apiBaseUrl}/api/auth/set-password?token=${token}`, { password });
      setMessage("Password set successfully! Closing window...");
      setTimeout(() => {
        window.location.href = "about:blank";
        setTimeout(() => window.close(), 100);
      }, 3000);
    } catch (error) {
      setMessage("Invalid or expired token. Please request a new link.");
      setTimeout(() => navigate(`/resend-link?token=${token}`), 3000);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="d-flex justify-content-center align-items-center" style={{ minHeight: '100vh', width: '100%', backgroundColor: '#f8f9fa' }}>
      {status === "loading" && <Spinner animation="border" className="d-block mx-auto" />}

      {status === "invalid" && (
        <Container className="p-4 shadow rounded bg-white text-center" style={{ maxWidth: '500px', width: '100%', margin: '0 20px' }}>
          <h4 className="text-center mb-4">Invalid or Expired Token</h4>
          <p>{message}</p>
          <Button variant="link" onClick={() => navigate(`/resend-link?token=${token}`)}>
            Request a new link
          </Button>
        </Container>
      )}

      {status === "already_set" && (
        <Container className="p-4 shadow rounded bg-white text-center" style={{ maxWidth: '500px', width: '100%', margin: '0 20px' }}>
          <h4 className="text-center mb-4">Set Your Password</h4>
          <p>Password has already been set. You can close this window.</p>
        </Container>
      )}

      {status === "valid" && (
        <Container className="p-4 shadow rounded bg-white" style={{ maxWidth: '500px', width: '100%', margin: '0 20px' }}>
          <h4 className="text-center mb-4">Set Your Password</h4>
          {/* Display error message if exists */}
          {message && (
            <div className={`alert text-center ${message.includes("successfully") ? "alert-success" : "alert-danger"}`}>
              {message}
            </div>
          )}
          <Form onSubmit={handleSubmit}>
            <Form.Group controlId="password" className="mb-3">
              <Form.Label>New Password</Form.Label>
              <InputGroup>
                <Form.Control
                  type={showPassword ? "text" : "password"}
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  required
                />
                <InputGroup.Text style={{ cursor: 'pointer' }} onClick={() => setShowPassword(!showPassword)}>
                  {showPassword ? <i className="bi bi-eye-slash"></i> : <i className="bi bi-eye"></i>}
                </InputGroup.Text>
              </InputGroup>
              <Form.Text className="text-muted">
                Password must be at least 8 characters, include a number and an uppercase letter.
              </Form.Text>
            </Form.Group>

            <Form.Group controlId="confirmPassword" className="mb-4">
              <Form.Label>Confirm Password</Form.Label>
              <InputGroup>
                <Form.Control
                  type={showConfirmPassword ? "text" : "password"}
                  value={confirmPassword}
                  onChange={(e) => setConfirmPassword(e.target.value)}
                  required
                />
                <InputGroup.Text style={{ cursor: 'pointer' }} onClick={() => setShowConfirmPassword(!showConfirmPassword)}>
                  {showConfirmPassword ? <i className="bi bi-eye-slash"></i> : <i className="bi bi-eye"></i>}
                </InputGroup.Text>
              </InputGroup>
            </Form.Group>

            <Button type="submit" disabled={loading} className="w-100" style={{ minHeight: '45px' }}>
              {loading ? <Spinner animation="border" size="sm" className="me-2" /> : "Set Password"}
            </Button>
          </Form>
        </Container>
      )}
    </div>
  );
}

export default PasswordSetup;
