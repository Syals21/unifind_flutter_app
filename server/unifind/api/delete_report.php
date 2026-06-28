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

$id = (int) ($_POST["id"] ?? 0);
$userId = (int) ($_POST["user_id"] ?? 0);

if ($id <= 0 || $userId <= 0) {
    echo json_encode(["status" => "error", "message" => "Invalid report request"]);
    exit;
}

try {
    // Check ownership before removing the report and its image.
    $find = $db->prepare("SELECT image FROM reports WHERE id = ? AND user_id = ? LIMIT 1");
    $find->execute([$id, $userId]);
    $report = $find->fetch();
    if (!$report) {
        echo json_encode(["status" => "error", "message" => "Report not found or you are not the owner"]);
        exit;
    }

    $stmt = $db->prepare("DELETE FROM reports WHERE id = ? AND user_id = ?");
    $stmt->execute([$id, $userId]);

    $image = (string) ($report["image"] ?? "");
    $imagePath = __DIR__ . "/../uploads/reports/" . $image;
    if ($image !== "" && file_exists($imagePath)) {
        unlink($imagePath);
    }

    echo json_encode(["status" => "success", "message" => "Report deleted successfully"]);
} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
