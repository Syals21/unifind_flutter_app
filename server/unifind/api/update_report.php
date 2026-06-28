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

function update_error($message, $code = 400) {
    http_response_code($code);
    echo json_encode(["status" => "error", "message" => $message]);
    exit;
}

$id = (int) ($_POST["id"] ?? 0);
$userId = (int) ($_POST["user_id"] ?? 0);
$reportType = trim($_POST["report_type"] ?? "");
$title = trim($_POST["title"] ?? "");
$category = trim($_POST["category"] ?? "");
$description = trim($_POST["description"] ?? "");
$location = trim($_POST["location"] ?? "");
$reportDate = trim($_POST["report_date"] ?? "");
$status = trim($_POST["status"] ?? "Unclaimed");
$imageData = trim($_POST["image"] ?? "NA");

if ($id <= 0 || $userId <= 0 || $reportType === "" || $title === "" ||
    $category === "" || $description === "" || $location === "" || $reportDate === "") {
    update_error("Please complete all required fields");
}
if (!in_array($reportType, ["Lost", "Found"], true) ||
    !in_array($status, ["Unclaimed", "Claimed"], true)) {
    update_error("Invalid report data");
}

try {
    // A report can only be changed by the user who created it.
    $find = $db->prepare("SELECT image FROM reports WHERE id = ? AND user_id = ? LIMIT 1");
    $find->execute([$id, $userId]);
    $existing = $find->fetch();
    if (!$existing) {
        update_error("Report not found or you are not the owner", 404);
    }

    $savedImage = (string) ($existing["image"] ?? "");
    if ($imageData !== "" && strtoupper($imageData) !== "NA") {
        $decodedImage = base64_decode($imageData, true);
        if ($decodedImage === false) {
            update_error("Invalid image data");
        }
        $uploadDir = __DIR__ . "/../uploads/reports/";
        if (!is_dir($uploadDir)) {
            mkdir($uploadDir, 0775, true);
        }
        $savedImage = "report_" . $id . ".jpg";
        if (file_put_contents($uploadDir . $savedImage, $decodedImage) === false) {
            update_error("Unable to save report image", 500);
        }
    }

    $stmt = $db->prepare("
        UPDATE reports SET
            report_type = ?, title = ?, category = ?, description = ?,
            location = ?, report_date = ?, status = ?, image = ?,
            updated_at = datetime('now', 'localtime')
        WHERE id = ? AND user_id = ?
    ");
    $stmt->execute([
        $reportType, $title, $category, $description, $location,
        $reportDate, $status, $savedImage, $id, $userId
    ]);

    echo json_encode(["status" => "success", "message" => "Report updated successfully"]);
} catch (Throwable $e) {
    update_error($e->getMessage(), 500);
}
