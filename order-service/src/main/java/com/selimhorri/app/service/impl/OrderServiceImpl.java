package com.selimhorri.app.service.impl;

import java.util.List;
import java.util.stream.Collectors;

import javax.transaction.Transactional;

import org.springframework.stereotype.Service;

import com.selimhorri.app.dto.OrderDto;
import com.selimhorri.app.exception.wrapper.OrderNotFoundException;
import com.selimhorri.app.helper.OrderMappingHelper;
import com.selimhorri.app.repository.OrderRepository;
import com.selimhorri.app.service.OrderService;

import io.github.resilience4j.bulkhead.annotation.Bulkhead;
import io.github.resilience4j.circuitbreaker.annotation.CircuitBreaker;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Service
@Transactional
@Slf4j
@RequiredArgsConstructor
public class OrderServiceImpl implements OrderService {

    private final OrderRepository orderRepository;

    @Override
    @Bulkhead(name = "orderDbBulkhead", type = Bulkhead.Type.THREADPOOL)
    @CircuitBreaker(name = "orderDb", fallbackMethod = "fallbackFindAll")
    public List<OrderDto> findAll() {
        log.info("*** OrderDto List, service; fetch all orders *");
        return this.orderRepository.findAll()
                .stream()
                .map(OrderMappingHelper::map)
                .distinct()
                .collect(Collectors.toUnmodifiableList());
    }

    /**
     * Fallback para cuando hay problemas con la bd, siguiendo el patron Ñ.
     */
    private List<OrderDto> fallbackFindAll(Throwable ex) {
        log.error("fallbackFindAll() invoked due to error in order-service findAll", ex);
        // Devolvemos lista vacía
        return List.of();
    }

    @Override
    @Bulkhead(name = "orderDbBulkhead", type = Bulkhead.Type.THREADPOOL)
    @CircuitBreaker(name = "orderDb", fallbackMethod = "fallbackFindById")
    public OrderDto findById(final Integer orderId) {
        log.info("*** OrderDto, service; fetch order by id *");
        return this.orderRepository.findById(orderId)
                .map(OrderMappingHelper::map)
                .orElseThrow(() -> new OrderNotFoundException(
                        String.format("Order with id: %d not found", orderId)));
    }

    /**
     * Fallback para cuando la bd o el servicio están caídos.
     */
    private OrderDto fallbackFindById(final Integer orderId, Throwable ex) {
        log.error("fallbackFindById() invoked for orderId={} due to error", orderId, ex);
        throw new OrderNotFoundException(
                String.format("Order service temporarily unavailable for id: %d", orderId));
    }

    @Override
    public OrderDto save(final OrderDto orderDto) {
        log.info("*** OrderDto, service; save order *");
        return OrderMappingHelper.map(this.orderRepository
                .save(OrderMappingHelper.map(orderDto)));
    }

    @Override
    public OrderDto update(final OrderDto orderDto) {
        log.info("*** OrderDto, service; update order *");
        return OrderMappingHelper.map(this.orderRepository
                .save(OrderMappingHelper.map(orderDto)));
    }

    @Override
    public OrderDto update(final Integer orderId, final OrderDto orderDto) {
        log.info("*** OrderDto, service; update order with orderId *");
        return OrderMappingHelper.map(this.orderRepository
                .save(OrderMappingHelper.map(this.findById(orderId))));
    }

    @Override
    public void deleteById(final Integer orderId) {
        log.info("*** Void, service; delete order by id *");
        this.orderRepository.delete(OrderMappingHelper.map(this.findById(orderId)));
    }
}
