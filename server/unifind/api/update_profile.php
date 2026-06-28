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
$id = (int) ($data["id"] ?? 0);
$name = trim($data["name"] ?? "");
$phone = trim($data["phone"] ?? "");

if ($id <= 0 || $name === "" || $phone === "") {
    echo json_encode(["status" => "error", "message" => "Name and phone are required"]);
    exit;
}

try {
    // Update only the profile fields that users are allowed to edit.
    $stmt = $db->prepare("UPDATE users SET name = ?, phone = ? WHERE id = ?");
    $stmt->execute([$name, $phone, $id]);
    echo json_encode([
        "status" => "success",
        "message" => "Profile updated successfully",
        "user" => ["id" => $id, "name" => $name, "phone" => $phone]
    ]);
} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
