package com.selimhorri.app.service.impl;

import java.util.List;
import java.util.stream.Collectors;

import javax.transaction.Transactional;

import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import com.selimhorri.app.constant.AppConstant;
import com.selimhorri.app.dto.OrderDto;
import com.selimhorri.app.dto.PaymentDto;
import com.selimhorri.app.exception.wrapper.PaymentNotFoundException;
import com.selimhorri.app.helper.PaymentMappingHelper;
import com.selimhorri.app.repository.PaymentRepository;
import com.selimhorri.app.service.PaymentService;

import io.github.resilience4j.bulkhead.annotation.Bulkhead;
import io.github.resilience4j.circuitbreaker.annotation.CircuitBreaker;
import io.github.resilience4j.retry.annotation.Retry;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Service
@Transactional
@Slf4j
@RequiredArgsConstructor
public class PaymentServiceImpl implements PaymentService {

    private final PaymentRepository paymentRepository;
    private final RestTemplate restTemplate;

    @Override
    @Bulkhead(name = "paymentFindAllBulkhead", type = Bulkhead.Type.THREADPOOL)
    @Retry(name = "paymentFindAllRetry")
    @CircuitBreaker(name = "paymentFindAllCb", fallbackMethod = "fallbackFindAll")
    public List<PaymentDto> findAll() {
        log.info("*** PaymentDto List, service; fetch all payments *");
        return this.paymentRepository.findAll()
                .stream()
                .map(PaymentMappingHelper::map)
                .map(p -> {
                    // Llamada remota al servicio de órdenes para obtener el detalle
                    OrderDto order = this.restTemplate.getForObject(
                            AppConstant.DiscoveredDomainsApi.ORDER_SERVICE_API_URL + "/" + p.getOrderDto().getOrderId(),
                            OrderDto.class);
                    p.setOrderDto(order);
                    return p;
                })
                .distinct()
                .collect(Collectors.toUnmodifiableList());
    }

    /**
     * Fallback para cuando falla la comunicación con el servicio.
     * Devolvemos los pagos sin detalle de orden.
     */
    private List<PaymentDto> fallbackFindAll(Throwable ex) {
        log.error("fallbackFindAll() in payment-service invoked due to error contacting order-service", ex);
        return this.paymentRepository.findAll()
                .stream()
                .map(PaymentMappingHelper::map)
                // aquí no se llama a restTemplate para no volver a romper
                .distinct()
                .collect(Collectors.toUnmodifiableList());
    }

    @Override
    @Bulkhead(name = "paymentFindByIdBulkhead", type = Bulkhead.Type.THREADPOOL)
    @Retry(name = "paymentFindByIdRetry")
    @CircuitBreaker(name = "paymentFindByIdCb", fallbackMethod = "fallbackFindById")
    public PaymentDto findById(final Integer paymentId) {
        log.info("*** PaymentDto, service; fetch payment by id *");
        return this.paymentRepository.findById(paymentId)
                .map(PaymentMappingHelper::map)
                .map(p -> {
                    OrderDto order = this.restTemplate.getForObject(
                            AppConstant.DiscoveredDomainsApi.ORDER_SERVICE_API_URL + "/" + p.getOrderDto().getOrderId(),
                            OrderDto.class);
                    p.setOrderDto(order);
                    return p;
                })
                .orElseThrow(() -> new PaymentNotFoundException(
                        String.format("Payment with id: %d not found", paymentId)));
    }

    /**
     * Fallback para  cuando el serviico está caído o lento.
     * Devolvemos el dto sin el detalle de la orden.
     */
    private PaymentDto fallbackFindById(final Integer paymentId, Throwable ex) {
        log.error("fallbackFindById() in payment-service invoked for id={} due to error contacting order-service",
                paymentId, ex);

        return this.paymentRepository.findById(paymentId)
                .map(PaymentMappingHelper::map)
                .orElseThrow(() -> new PaymentNotFoundException(
                        String.format("Payment with id: %d not found or service unavailable", paymentId)));
    }

    @Override
    public PaymentDto save(final PaymentDto paymentDto) {
        log.info("*** PaymentDto, service; save payment *");
        return PaymentMappingHelper.map(this.paymentRepository
                .save(PaymentMappingHelper.map(paymentDto)));
    }

    @Override
    public PaymentDto update(final PaymentDto paymentDto) {
        log.info("*** PaymentDto, service; update payment *");
        return PaymentMappingHelper.map(this.paymentRepository
                .save(PaymentMappingHelper.map(paymentDto)));
    }

    @Override
    public void deleteById(final Integer paymentId) {
        log.info("*** Void, service; delete payment by id *");
        this.paymentRepository.deleteById(paymentId);
    }
}
