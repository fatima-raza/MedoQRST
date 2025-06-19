import { useState, useEffect } from "react";
import { useNavigate, useLocation } from "react-router-dom";
import axios from "axios";
import { Container, Form, Button, Spinner, InputGroup } from "react-bootstrap";
const apiBaseUrl = import.meta.env.VITE_API_BASE_URL;

function PasswordReset() {
  const location = useLocation();
  const queryParams = new URLSearchParams(location.search);
  const token = queryParams.get("token");
  const [status, setStatus] = useState("loading");
  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [message, setMessage] = useState("");
  const [loading, setLoading] = useState(false);
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);
  const navigate = useNavigate();

  useEffect(() => {
    document.title = "Reset Your Password";
    if (!token) {
      setStatus("invalid");
      setMessage("Invalid or expired link. Please request a new one.");
      return;
    }
    verifyToken();
  }, [token]);

  const verifyToken = async () => {
    try {
      const response = await axios.get(
        `${apiBaseUrl}/api/auth/verify-reset-token?token=${token}`
      );
      setStatus(response.data.status);
    } catch (error) {
      setStatus("invalid");
      setMessage("Invalid or expired link. Please request a new one.");
    }
  };

  const validatePassword = (pwd) => {
    return pwd.length >= 8 && /[A-Z]/.test(pwd) && /\d/.test(pwd);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setMessage("");

    if (!validatePassword(password)) {
      setMessage(
        "Password must be at least 8 characters, includes a number and an uppercase letter."
      );
      return;
    }
    if (password !== confirmPassword) {
      setMessage("Passwords do not match");
      return;
    }

    setLoading(true);
    try {
      await axios.post(`${apiBaseUrl}/api/auth/reset-password?token=${token}`, {
        newPassword: password,
      });
      setMessage("Password reset successfully! Closing window...");
      setTimeout(() => {
        window.location.href = "about:blank";
        setTimeout(() => window.close(), 100);
      }, 3000);
    } catch (error) {
      setMessage("Invalid or expired token. Please request a new link.");
      setStatus("invalid");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div
      className="d-flex justify-content-center align-items-center"
      style={{ minHeight: "100vh", width: "100%", backgroundColor: "#f8f9fa" }}
    >
      {status === "loading" && (
        <Spinner animation="border" className="d-block mx-auto" />
      )}

      {status === "invalid" && (
        <Container
          className="p-4 shadow rounded bg-white text-center"
          style={{ maxWidth: "500px", width: "100%", margin: "0 20px" }}
        >
          <h4 className="text-center mb-4">Invalid or Expired Token</h4>
          <p>{message}</p>
        </Container>
      )}

      {status === "valid" && (
        <Container
          className="p-4 shadow rounded bg-white"
          style={{ maxWidth: "500px", width: "100%", margin: "0 20px" }}
        >
          <h4 className="text-center mb-4">Reset Your Password</h4>
          {message && (
            <div
              className={`alert text-center ${
                message.includes("successfully")
                  ? "alert-success"
                  : "alert-danger"
              }`}
            >
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
                <InputGroup.Text
                  style={{ cursor: "pointer" }}
                  onClick={() => setShowPassword(!showPassword)}
                >
                  {showPassword ? (
                    <i className="bi bi-eye-slash"></i>
                  ) : (
                    <i className="bi bi-eye"></i>
                  )}
                </InputGroup.Text>
              </InputGroup>
              <Form.Text className="text-muted">
                Password must be at least 8 characters, include a number and an
                uppercase letter.
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
                <InputGroup.Text
                  style={{ cursor: "pointer" }}
                  onClick={() => setShowConfirmPassword(!showConfirmPassword)}
                >
                  {showConfirmPassword ? (
                    <i className="bi bi-eye-slash"></i>
                  ) : (
                    <i className="bi bi-eye"></i>
                  )}
                </InputGroup.Text>
              </InputGroup>
            </Form.Group>

            <Button
              type="submit"
              disabled={loading}
              className="w-100"
              style={{ minHeight: "45px" }}
            >
              {loading ? (
                <Spinner animation="border" size="sm" className="me-2" />
              ) : (
                "Reset Password"
              )}
            </Button>
          </Form>
        </Container>
      )}
    </div>
  );
}

export default PasswordReset;
