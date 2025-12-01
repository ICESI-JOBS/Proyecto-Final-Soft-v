package com.selimhorri.app.service.impl;

import java.util.List;
import java.util.stream.Collectors;

import javax.transaction.Transactional;

import org.springframework.stereotype.Service;

import com.selimhorri.app.dto.ProductDto;
import com.selimhorri.app.exception.wrapper.ProductNotFoundException;
import com.selimhorri.app.helper.ProductMappingHelper;
import com.selimhorri.app.repository.ProductRepository;
import com.selimhorri.app.service.ProductService;

import io.github.resilience4j.bulkhead.annotation.Bulkhead;
import io.github.resilience4j.circuitbreaker.annotation.CircuitBreaker;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Service
@Transactional
@Slf4j
@RequiredArgsConstructor
public class ProductServiceImpl implements ProductService {

    private final ProductRepository productRepository;

    @Override
    @Bulkhead(name = "productReadBulkhead", type = Bulkhead.Type.THREADPOOL)
    @CircuitBreaker(name = "productDb", fallbackMethod = "fallbackFindAll")
    public List<ProductDto> findAll() {
        log.info("*** ProductDto List, service; fetch all products *");
        return this.productRepository.findAll()
                .stream()
                .map(ProductMappingHelper::map)
                .distinct()
                .collect(Collectors.toUnmodifiableList());
    }

    private List<ProductDto> fallbackFindAll(Throwable ex) {
        log.error("fallbackFindAll() in product-service invoked due to DB error", ex);
        return List.of();
    }

    @Override
    @Bulkhead(name = "productReadBulkhead", type = Bulkhead.Type.THREADPOOL)
    @CircuitBreaker(name = "productDb", fallbackMethod = "fallbackFindById")
    public ProductDto findById(final Integer productId) {
        log.info("*** ProductDto, service; fetch product by id *");
        return this.productRepository.findById(productId)
                .map(ProductMappingHelper::map)
                .orElseThrow(() -> new ProductNotFoundException(
                        String.format("Product with id: %d not found", productId)));
    }

    private ProductDto fallbackFindById(final Integer productId, Throwable ex) {
        log.error("fallbackFindById() in product-service invoked for id={} due to DB error", productId, ex);
        throw new ProductNotFoundException(
                String.format("Product service temporarily unavailable for id: %d", productId));
    }

    @Override
    public ProductDto save(final ProductDto productDto) {
        log.info("*** ProductDto, service; save product *");
        return ProductMappingHelper.map(this.productRepository
                .save(ProductMappingHelper.map(productDto)));
    }

    @Override
    public ProductDto update(final ProductDto productDto) {
        log.info("*** ProductDto, service; update product *");
        return ProductMappingHelper.map(this.productRepository
                .save(ProductMappingHelper.map(productDto)));
    }

    @Override
    public ProductDto update(final Integer productId, final ProductDto productDto) {
        log.info("*** ProductDto, service; update product with productId *");
        return ProductMappingHelper.map(this.productRepository
                .save(ProductMappingHelper.map(this.findById(productId))));
    }

    @Override
    public void deleteById(final Integer productId) {
        log.info("*** Void, service; delete product by id *");
        this.productRepository.delete(ProductMappingHelper
                .map(this.findById(productId)));
    }
}
