<?php

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: Content-Type");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Content-Type: application/json");
date_default_timezone_set("Asia/Kuala_Lumpur");

if (($_SERVER["REQUEST_METHOD"] ?? "") === "OPTIONS") {
    http_response_code(200);
    exit;
}

require_once "db.php";

function report_error($message, $code = 400) {
    http_response_code($code);
    echo json_encode(["status" => "error", "message" => $message]);
    exit;
}

$userId = (int) ($_POST["user_id"] ?? 0);
$reportType = trim($_POST["report_type"] ?? "");
$title = trim($_POST["title"] ?? "");
$category = trim($_POST["category"] ?? "");
$description = trim($_POST["description"] ?? "");
$location = trim($_POST["location"] ?? "");
$reportDate = trim($_POST["report_date"] ?? "");
$imageData = trim($_POST["image"] ?? "");

if ($userId <= 0 || $reportType === "" || $title === "" || $category === "" ||
    $description === "" || $location === "" || $reportDate === "") {
    report_error("Please complete all required fields");
}
if (!in_array($reportType, ["Lost", "Found"], true)) {
    report_error("Invalid report type");
}

try {
    $userCheck = $db->prepare("SELECT id FROM users WHERE id = ?");
    $userCheck->execute([$userId]);
    if (!$userCheck->fetch()) {
        report_error("User not found", 404);
    }

    $stmt = $db->prepare("
        INSERT INTO reports (
            user_id, report_type, title, category, description,
            location, report_date, status
        ) VALUES (?, ?, ?, ?, ?, ?, ?, 'Unclaimed')
    ");
    $stmt->execute([
        $userId, $reportType, $title, $category,
        $description, $location, $reportDate
    ]);
    $reportId = (int) $db->lastInsertId();
    $savedImage = "";

    // Save the optional image after the report ID has been created.
    if ($imageData !== "") {
        $decodedImage = base64_decode($imageData, true);
        if ($decodedImage === false) {
            report_error("Invalid image data");
        }
        $uploadDir = __DIR__ . "/../uploads/reports/";
        if (!is_dir($uploadDir)) {
            mkdir($uploadDir, 0775, true);
        }
        $savedImage = "report_" . $reportId . ".jpg";
        if (file_put_contents($uploadDir . $savedImage, $decodedImage) === false) {
            report_error("Unable to save report image", 500);
        }
        $updateImage = $db->prepare("UPDATE reports SET image = ? WHERE id = ?");
        $updateImage->execute([$savedImage, $reportId]);
    }

    echo json_encode([
        "status" => "success",
        "message" => "Report added successfully",
        "report_id" => $reportId,
        "image" => $savedImage
    ]);
} catch (Throwable $e) {
    report_error($e->getMessage(), 500);
}
