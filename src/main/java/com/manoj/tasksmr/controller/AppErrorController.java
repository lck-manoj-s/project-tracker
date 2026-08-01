package com.manoj.tasksmr.controller;

import jakarta.servlet.RequestDispatcher;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.boot.web.servlet.error.ErrorController;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.RequestMapping;

@Controller
public class AppErrorController implements ErrorController {

    @RequestMapping("/error")
    public String handleError(HttpServletRequest request, Model model) {
        Object statusCode = request.getAttribute(RequestDispatcher.ERROR_STATUS_CODE);
        Object message    = request.getAttribute(RequestDispatcher.ERROR_MESSAGE);

        int status = statusCode != null ? Integer.parseInt(statusCode.toString()) : 500;
        String errorTitle;
        String errorDetail;

        switch (status) {
            case 404 -> {
                errorTitle  = "Page Not Found";
                errorDetail = "The page you're looking for doesn't exist or has been moved.";
            }
            case 403 -> {
                errorTitle  = "Access Denied";
                errorDetail = "You don't have permission to access this page.";
            }
            case 500 -> {
                errorTitle  = "Server Error";
                errorDetail = "Something went wrong on our end. Please try again later.";
            }
            default -> {
                errorTitle  = "Unexpected Error";
                errorDetail = message != null && !message.toString().isBlank()
                        ? message.toString()
                        : "An unexpected error occurred.";
            }
        }

        model.addAttribute("status",      status);
        model.addAttribute("errorTitle",  errorTitle);
        model.addAttribute("errorDetail", errorDetail);
        return "error";
    }
}
