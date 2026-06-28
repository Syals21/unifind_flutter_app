<?php

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: Content-Type");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Content-Type: application/json");

if (($_SERVER["REQUEST_METHOD"] ?? "") === "OPTIONS") {
    http_response_code(200);
    exit;
}

require_once "db.php";

$data = json_decode(file_get_contents("php://input"), true) ?? [];
$name = trim($data["name"] ?? "");
$email = strtolower(trim($data["email"] ?? ""));
$phone = trim($data["phone"] ?? "");
$password = (string) ($data["password"] ?? "");

if ($name === "" || $email === "" || $phone === "" || $password === "") {
    echo json_encode(["status" => "error", "message" => "All fields are required"]);
    exit;
}

if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    echo json_encode(["status" => "error", "message" => "Please enter a valid email"]);
    exit;
}

if (strlen($password) < 6) {
    echo json_encode(["status" => "error", "message" => "Password must have at least 6 characters"]);
    exit;
}

if (!preg_match('/^[0-9+\-\s]{8,20}$/', $phone)) {
    echo json_encode(["status" => "error", "message" => "Please enter a valid phone number"]);
    exit;
}

try {
    // Do not allow two accounts to use the same email.
    $check = $db->prepare("SELECT id FROM users WHERE email = ? LIMIT 1");
    $check->execute([$email]);
    if ($check->fetch()) {
        echo json_encode(["status" => "error", "message" => "Email is already registered"]);
        exit;
    }

    $stmt = $db->prepare("
        INSERT INTO users (name, email, phone, password)
        VALUES (?, ?, ?, ?)
    ");
    $stmt->execute([$name, $email, $phone, password_hash($password, PASSWORD_DEFAULT)]);

    echo json_encode([
        "status" => "success",
        "message" => "Registration successful. You may now log in."
    ]);
} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
