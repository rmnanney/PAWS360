package com.uwm.paws360.Controller;

import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.awt.*;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import javax.imageio.ImageIO;

/**
 * Controller to provide placeholder images for the frontend
 * Generates simple colored placeholder images dynamically
 */
@RestController
@RequestMapping("/api/placeholder")
public class PlaceholderController {

    @GetMapping("/{width}/{height}")
    public ResponseEntity<byte[]> getPlaceholder(
            @PathVariable int width, 
            @PathVariable int height) {
        
        try {
            // Create a simple placeholder image
            BufferedImage image = new BufferedImage(width, height, BufferedImage.TYPE_INT_RGB);
            Graphics2D g2d = image.createGraphics();
            
            // Set background color (light gray)
            g2d.setColor(new Color(220, 220, 220));
            g2d.fillRect(0, 0, width, height);
            
            // Add border
            g2d.setColor(new Color(180, 180, 180));
            g2d.drawRect(0, 0, width - 1, height - 1);
            
            // Add text
            g2d.setColor(new Color(120, 120, 120));
            g2d.setFont(new Font("Arial", Font.BOLD, Math.max(12, Math.min(width, height) / 8)));
            FontMetrics fm = g2d.getFontMetrics();
            String text = width + "×" + height;
            int textWidth = fm.stringWidth(text);
            int textHeight = fm.getHeight();
            g2d.drawString(text, (width - textWidth) / 2, (height + textHeight) / 2 - 3);
            
            g2d.dispose();
            
            // Convert to PNG bytes
            ByteArrayOutputStream baos = new ByteArrayOutputStream();
            ImageIO.write(image, "png", baos);
            byte[] imageBytes = baos.toByteArray();
            
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.IMAGE_PNG);
            headers.setContentLength(imageBytes.length);
            headers.setCacheControl("public, max-age=3600"); // Cache for 1 hour
            
            return new ResponseEntity<>(imageBytes, headers, HttpStatus.OK);
            
        } catch (IOException e) {
            return new ResponseEntity<>(HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
}