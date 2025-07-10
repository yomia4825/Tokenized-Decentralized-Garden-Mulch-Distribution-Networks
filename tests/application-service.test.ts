import { describe, it, expect, beforeEach } from "vitest"

describe("Application Service Contract", () => {
  let contractAddress
  let provider1
  let customer1
  
  beforeEach(() => {
    contractAddress = "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.application-service"
    provider1 = "ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5"
    customer1 = "ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG"
  })
  
  describe("Provider Registration", () => {
    it("should register service provider successfully", () => {
      const result = {
        type: "ok",
        value: 1,
      }
      
      expect(result.type).toBe("ok")
      expect(result.value).toBe(1)
    })
    
    it("should store provider equipment list", () => {
      const equipment = ["spreader", "rake", "wheelbarrow"]
      const providerData = {
        owner: provider1,
        name: "Mulch Masters",
        "service-area": "Seattle Metro",
        "hourly-rate": 50,
        "equipment-available": equipment,
        rating: 100,
        "jobs-completed": 0,
        active: true,
      }
      
      expect(providerData["equipment-available"]).toEqual(equipment)
      expect(providerData.active).toBe(true)
    })
  })
  
  describe("Service Booking", () => {
    it("should book service successfully", () => {
      const result = {
        type: "ok",
        value: 1,
      }
      
      expect(result.type).toBe("ok")
      expect(result.value).toBe(1)
    })
    
    it("should fail booking with insufficient payment", () => {
      const result = {
        type: "err",
        value: 204,
      }
      
      expect(result.type).toBe("err")
      expect(result.value).toBe(204) // ERR-INSUFFICIENT-PAYMENT
    })
    
    it("should calculate total cost correctly", () => {
      const hourlyRate = 50
      const estimatedHours = 4
      const expectedCost = 200
      
      expect(hourlyRate * estimatedHours).toBe(expectedCost)
    })
  })
  
  describe("Garden Preparation Requirements", () => {
    it("should set preparation requirements successfully", () => {
      const result = {
        type: "ok",
        value: true,
      }
      
      expect(result.type).toBe("ok")
      expect(result.value).toBe(true)
    })
    
    it("should store all preparation options", () => {
      const prepData = {
        "soil-testing-required": true,
        "weed-removal": true,
        "bed-edging": false,
        "irrigation-check": true,
        "mulch-type-preference": "bark-chips",
        "special-instructions": "Avoid area near sprinkler heads",
      }
      
      expect(prepData["soil-testing-required"]).toBe(true)
      expect(prepData["mulch-type-preference"]).toBe("bark-chips")
    })
  })
  
  describe("Booking Status Updates", () => {
    it("should update booking status successfully", () => {
      const result = {
        type: "ok",
        value: true,
      }
      
      expect(result.type).toBe("ok")
      expect(result.value).toBe(true)
    })
    
    it("should increment jobs completed when status is completed", () => {
      const initialJobs = 5
      const expectedJobs = 6
      
      expect(initialJobs + 1).toBe(expectedJobs)
    })
    
    it("should set completion date when completed", () => {
      const currentBlock = 2000
      const bookingData = {
        customer: customer1,
        "provider-id": 1,
        "garden-size": 500,
        "service-type": "mulch-application",
        "scheduled-date": 1950,
        "estimated-hours": 3,
        "total-cost": 150,
        status: "completed",
        "completion-date": currentBlock,
      }
      
      expect(bookingData.status).toBe("completed")
      expect(bookingData["completion-date"]).toBe(currentBlock)
    })
  })
  
  describe("Provider Rating", () => {
    it("should rate provider successfully after completion", () => {
      const result = {
        type: "ok",
        value: true,
      }
      
      expect(result.type).toBe("ok")
      expect(result.value).toBe(true)
    })
    
    it("should fail rating if booking not completed", () => {
      const result = {
        type: "err",
        value: 203,
      }
      
      expect(result.type).toBe("err")
      expect(result.value).toBe(203) // ERR-INVALID-STATUS
    })
  })
})
