<?php
header("Content-Type: application/json");

// Include the database configuration file
include_once 'dbconfig.php';

// Check if the connection from dbconfig.php is available
if (!$conn) {
    echo json_encode(["status" => "error", "message" => "Database connection not available"]);
    exit();
}

// Check if data is sent via POST method
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // Get data from the POST request
    $temp_treshold = isset($_POST['temp_treshold']) ? floatval($_POST['temp_treshold']) : null;
    $hum_treshold = isset($_POST['hum_treshold']) ? floatval($_POST['hum_treshold']) : null;

    // Validate received data
    if ($temp_treshold !== null && $hum_treshold !== null) {
        // Prepare the update statement
        $stmt = $conn->prepare("UPDATE treshold_controller SET temp_treshold = ?, hum_treshold = ?");
        $stmt->bind_param("dd", $temp_treshold, $hum_treshold);

        // Execute the statement
        if ($stmt->execute()) {
            if ($stmt->affected_rows > 0) {
                echo json_encode(["status" => "success", "message" => "Thresholds updated successfully"]);
            } else {
                echo json_encode(["status" => "error", "message" => "No row found with the provided ID or no changes made"]);
            }
        } else {
            echo json_encode(["status" => "error", "message" => "Error updating record: " . $stmt->error]);
        }

        $stmt->close();
    } else {
        echo json_encode(["status" => "error", "message" => "Missing required parameters"]);
    }
} else {
    echo json_encode(["status" => "error", "message" => "Invalid request method"]);
}

// Close the database connection (assuming $conn is available)
if ($conn) {
    $conn->close();
}
?>