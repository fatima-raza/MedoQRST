import { BrowserRouter as Router, Routes, Route, Navigate } from "react-router-dom";
import { useSearchParams, useNavigate } from "react-router-dom";
import PasswordSetup from "./pages/PasswordSetup";
import ResendSetupLink from "./pages/ResendSetupLink";
import PasswordReset from "./pages/PasswordReset";

// Add this import at the top
import { useLocation } from "react-router-dom";

// Component to check token and redirect accordingly
function TokenValidator() {
  const [searchParams] = useSearchParams();
  const token = searchParams.get("token");

  return token ? <PasswordSetup token={token} /> : <Navigate to="/resend-link" />;
}

function App() {
  return (
    <Router>
      <Routes>
        <Route path="/set-password" element={<TokenValidator />} />
        <Route path="/reset-password" element={<PasswordReset />} />
        <Route path="/resend-link" element={<ResendSetupLink />} />
        {/* More explicit redirect for root path */}
        <Route path="/" element={<Navigate to="/resend-link" />} />
        {/* Catch-all route */}
        <Route path="*" element={<Navigate to="/resend-link" />} />
      </Routes>
    </Router>
  );
}



export default App;
