const checkLogin = (req, res, next) => {
    if (!req.session.userId) {
        return res.status(401).json({ error: "Unauthorized, please log in." });
    }
    next(); // If logged in, allow the request to proceed
};

module.exports = checkLogin;