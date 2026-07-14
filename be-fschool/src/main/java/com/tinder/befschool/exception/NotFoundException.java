package com.tinder.befschool.exception;

public class NotFoundException extends ApiException {
    public NotFoundException(String message) {
        super(message);
    }
}
