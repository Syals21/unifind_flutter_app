<?php

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: Content-Type");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Content-Type: application/json");

if (($_SERVER["REQUEST_METHOD"] ?? "") === "OPTIONS") {
    http_response_code(200);
    exit;
}

require_once "db.php";

try {
    $page = max(1, (int) ($_GET["page"] ?? 1));
    $limit = max(1, min(100, (int) ($_GET["limit"] ?? 10)));
    $search = trim($_GET["search"] ?? "");
    $reportType = trim($_GET["report_type"] ?? "All");
    $category = trim($_GET["category"] ?? "All");
    $status = trim($_GET["status"] ?? "All");
    $userId = (int) ($_GET["user_id"] ?? 0);

    // Build the WHERE clause from the filters sent by Flutter.
    $where = [];
    $params = [];

    if ($search !== "") {
        $where[] = "(r.title LIKE :search OR r.description LIKE :search OR r.location LIKE :search)";
        $params[":search"] = "%" . $search . "%";
    }
    if ($reportType !== "" && strcasecmp($reportType, "All") !== 0) {
        $where[] = "r.report_type = :report_type";
        $params[":report_type"] = $reportType;
    }
    if ($category !== "" && strcasecmp($category, "All") !== 0) {
        $where[] = "r.category = :category";
        $params[":category"] = $category;
    }
    if ($status !== "" && strcasecmp($status, "All") !== 0) {
        $where[] = "r.status = :status";
        $params[":status"] = $status;
    }
    if ($userId > 0) {
        $where[] = "r.user_id = :user_id";
        $params[":user_id"] = $userId;
    }

    $whereSql = empty($where) ? "" : " WHERE " . implode(" AND ", $where);
    $countStmt = $db->prepare("SELECT COUNT(*) FROM reports r" . $whereSql);
    foreach ($params as $key => $value) {
        $countStmt->bindValue($key, $value);
    }
    $countStmt->execute();
    $totalItems = (int) $countStmt->fetchColumn();
    $totalPages = max(1, (int) ceil($totalItems / $limit));
    $page = min($page, $totalPages);
    $offset = ($page - 1) * $limit;

    // Join users so each report includes the reporter's contact details.
    $stmt = $db->prepare("
        SELECT
            r.id, r.user_id, r.report_type, r.title, r.category,
            r.description, r.location, r.report_date, r.status,
            r.image, r.created_at, r.updated_at,
            u.name AS user_name, u.email AS user_email, u.phone AS user_phone
        FROM reports r
        INNER JOIN users u ON u.id = r.user_id
        $whereSql
        ORDER BY r.id DESC
        LIMIT :limit OFFSET :offset
    ");
    foreach ($params as $key => $value) {
        $stmt->bindValue($key, $value);
    }
    $stmt->bindValue(":limit", $limit, PDO::PARAM_INT);
    $stmt->bindValue(":offset", $offset, PDO::PARAM_INT);
    $stmt->execute();

    echo json_encode([
        "status" => "success",
        "reports" => $stmt->fetchAll(),
        "current_page" => $page,
        "total_pages" => $totalPages,
        "total_items" => $totalItems
    ]);
} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
