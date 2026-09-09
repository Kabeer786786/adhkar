package com.sprnt.adhkar

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import java.util.Calendar
import java.util.TimeZone

class DndSchedulerTest {

    private val testTimeZone = TimeZone.getTimeZone("UTC")

    private fun createEpoch(year: Int, month: Int, day: Int, hour: Int, minute: Int): Long {
        val cal = Calendar.getInstance(testTimeZone).apply {
            set(Calendar.YEAR, year)
            set(Calendar.MONTH, month - 1) // 0-based
            set(Calendar.DAY_OF_MONTH, day)
            set(Calendar.HOUR_OF_DAY, hour)
            set(Calendar.MINUTE, minute)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        return cal.timeInMillis
    }

    @Test
    fun testIsOvernight() {
        assertTrue(DndScheduler.isOvernight(22, 0, 6, 0))
        assertTrue(DndScheduler.isOvernight(23, 59, 0, 1))
        assertFalse(DndScheduler.isOvernight(13, 0, 14, 0))
        assertFalse(DndScheduler.isOvernight(0, 0, 6, 0))
        assertFalse(DndScheduler.isOvernight(10, 30, 10, 30))
    }

    @Test
    fun testStandardSameDaySchedule() {
        // 13:15 to 13:40 (1:15 PM to 1:40 PM)
        val allDays = listOf(1, 2, 3, 4, 5, 6, 7)

        val beforeStart = createEpoch(2026, 8, 15, 13, 14)
        val atStart = createEpoch(2026, 8, 15, 13, 15)
        val during = createEpoch(2026, 8, 15, 13, 30)
        val atEnd = createEpoch(2026, 8, 15, 13, 40)
        val afterEnd = createEpoch(2026, 8, 15, 13, 41)

        assertFalse(DndScheduler.isInsideSchedule(beforeStart, 13, 15, 13, 40, true, allDays, testTimeZone))
        assertTrue(DndScheduler.isInsideSchedule(atStart, 13, 15, 13, 40, true, allDays, testTimeZone))
        assertTrue(DndScheduler.isInsideSchedule(during, 13, 15, 13, 40, true, allDays, testTimeZone))
        assertFalse(DndScheduler.isInsideSchedule(atEnd, 13, 15, 13, 40, true, allDays, testTimeZone))
        assertFalse(DndScheduler.isInsideSchedule(afterEnd, 13, 15, 13, 40, true, allDays, testTimeZone))
    }

    @Test
    fun testOvernightMidnightCrossingSchedule() {
        // 22:00 (10:00 PM) to 06:00 (6:00 AM)
        val allDays = listOf(1, 2, 3, 4, 5, 6, 7)

        val beforeStart = createEpoch(2026, 8, 15, 21, 59)
        val atStart = createEpoch(2026, 8, 15, 22, 0)
        val atMidnight = createEpoch(2026, 8, 16, 0, 0)
        val earlyMorning = createEpoch(2026, 8, 16, 5, 59)
        val atEnd = createEpoch(2026, 8, 16, 6, 0)
        val afterEnd = createEpoch(2026, 8, 16, 6, 1)

        assertFalse(DndScheduler.isInsideSchedule(beforeStart, 22, 0, 6, 0, true, allDays, testTimeZone))
        assertTrue(DndScheduler.isInsideSchedule(atStart, 22, 0, 6, 0, true, allDays, testTimeZone))
        assertTrue(DndScheduler.isInsideSchedule(atMidnight, 22, 0, 6, 0, true, allDays, testTimeZone))
        assertTrue(DndScheduler.isInsideSchedule(earlyMorning, 22, 0, 6, 0, true, allDays, testTimeZone))
        assertFalse(DndScheduler.isInsideSchedule(atEnd, 22, 0, 6, 0, true, allDays, testTimeZone))
        assertFalse(DndScheduler.isInsideSchedule(afterEnd, 22, 0, 6, 0, true, allDays, testTimeZone))
    }

    @Test
    fun testMidnightToMorningSchedule() {
        // 00:00 (12:00 AM) to 06:00 (6:00 AM)
        val allDays = listOf(1, 2, 3, 4, 5, 6, 7)

        val beforeStart = createEpoch(2026, 8, 15, 23, 59)
        val atStart = createEpoch(2026, 8, 16, 0, 0)
        val during = createEpoch(2026, 8, 16, 3, 0)
        val atEnd = createEpoch(2026, 8, 16, 6, 0)

        assertFalse(DndScheduler.isInsideSchedule(beforeStart, 0, 0, 6, 0, true, allDays, testTimeZone))
        assertTrue(DndScheduler.isInsideSchedule(atStart, 0, 0, 6, 0, true, allDays, testTimeZone))
        assertTrue(DndScheduler.isInsideSchedule(during, 0, 0, 6, 0, true, allDays, testTimeZone))
        assertFalse(DndScheduler.isInsideSchedule(atEnd, 0, 0, 6, 0, true, allDays, testTimeZone))
    }

    @Test
    fun testTwoMinuteMidnightCrossingSchedule() {
        // 23:59 to 00:01 (11:59 PM to 12:01 AM)
        val allDays = listOf(1, 2, 3, 4, 5, 6, 7)

        val before = createEpoch(2026, 8, 15, 23, 58)
        val atStart = createEpoch(2026, 8, 15, 23, 59)
        val atMidnight = createEpoch(2026, 8, 16, 0, 0)
        val atEnd = createEpoch(2026, 8, 16, 0, 1)

        assertFalse(DndScheduler.isInsideSchedule(before, 23, 59, 0, 1, true, allDays, testTimeZone))
        assertTrue(DndScheduler.isInsideSchedule(atStart, 23, 59, 0, 1, true, allDays, testTimeZone))
        assertTrue(DndScheduler.isInsideSchedule(atMidnight, 23, 59, 0, 1, true, allDays, testTimeZone))
        assertFalse(DndScheduler.isInsideSchedule(atEnd, 23, 59, 0, 1, true, allDays, testTimeZone))
    }

    @Test
    fun testWeekdayFiltering() {
        // 2026-08-15 is Saturday (Dart weekday = 6)
        // 2026-08-17 is Monday (Dart weekday = 1)
        val weekdaysMonFri = listOf(1, 2, 3, 4, 5)

        val saturdayAfternoon = createEpoch(2026, 8, 15, 13, 20)
        val mondayAfternoon = createEpoch(2026, 8, 17, 13, 20)

        // On Saturday, should be false
        assertFalse(DndScheduler.isInsideSchedule(saturdayAfternoon, 13, 15, 13, 40, false, weekdaysMonFri, testTimeZone))
        // On Monday, should be true
        assertTrue(DndScheduler.isInsideSchedule(mondayAfternoon, 13, 15, 13, 40, false, weekdaysMonFri, testTimeZone))
    }

    @Test
    fun testCalculateNextStartAndEnd() {
        val allDays = listOf(1, 2, 3, 4, 5, 6, 7)

        // 1. From before start time (12:00 PM), next 22:00 start is today at 22:00
        val fromBefore = createEpoch(2026, 8, 15, 12, 0)
        val expectedStartToday = createEpoch(2026, 8, 15, 22, 0)
        assertEquals(expectedStartToday, DndScheduler.calculateNextStart(fromBefore, 22, 0, true, allDays, testTimeZone))

        // 2. From inside the period (23:00 / 11:00 PM), next start is tomorrow at 22:00
        val fromInside = createEpoch(2026, 8, 15, 23, 0)
        val expectedStartTomorrow = createEpoch(2026, 8, 16, 22, 0)
        assertEquals(expectedStartTomorrow, DndScheduler.calculateNextStart(fromInside, 22, 0, true, allDays, testTimeZone))

        // 3. For overnight schedule (22:00 to 06:00) from 23:00, next end is tomorrow at 06:00
        val expectedEndTomorrow = createEpoch(2026, 8, 16, 6, 0)
        assertEquals(expectedEndTomorrow, DndScheduler.calculateNextEnd(fromInside, 22, 0, 6, 0, true, allDays, testTimeZone))
    }
}
