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
$email = strtolower(trim($data["email"] ?? ""));
$password = (string) ($data["password"] ?? "");

if ($email === "" || $password === "") {
    echo json_encode(["status" => "error", "message" => "Email and password are required"]);
    exit;
}

try {
    $stmt = $db->prepare("
        SELECT id, name, email, phone, password, created_at
        FROM users
        WHERE email = ?
        LIMIT 1
    ");
    $stmt->execute([$email]);
    $user = $stmt->fetch();

    // Check the submitted password against the stored password hash.
    if (!$user || !password_verify($password, $user["password"])) {
        echo json_encode(["status" => "error", "message" => "Invalid email or password"]);
        exit;
    }

    unset($user["password"]);
    echo json_encode([
        "status" => "success",
        "message" => "Login successful",
        "user" => $user
    ]);
} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
