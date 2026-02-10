package com.uwm.paws360.Controller;

import com.uwm.paws360.DTO.Finances.*;
import com.uwm.paws360.Service.FinancesService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/finances")
public class FinancesController {

    private final FinancesService financesService;

    public FinancesController(FinancesService financesService) {
        this.financesService = financesService;
    }

    @GetMapping("/student/{studentId}/summary")
    public ResponseEntity<FinancesSummaryResponseDTO> summary(@PathVariable Integer studentId) {
        return ResponseEntity.ok(financesService.getSummary(studentId));
    }

    @GetMapping("/student/{studentId}/transactions")
    public ResponseEntity<List<TransactionDTO>> transactions(@PathVariable Integer studentId) {
        return ResponseEntity.ok(financesService.listTransactions(studentId));
    }

    @GetMapping("/student/{studentId}/aid")
    public ResponseEntity<AidOverviewDTO> aid(@PathVariable Integer studentId) {
        return ResponseEntity.ok(financesService.getAidOverview(studentId));
    }

    @GetMapping("/student/{studentId}/payment-plans")
    public ResponseEntity<List<PaymentPlanDTO>> paymentPlans(@PathVariable Integer studentId) {
        return ResponseEntity.ok(financesService.listPaymentPlans(studentId));
    }
}

