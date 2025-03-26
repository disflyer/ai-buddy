import { NextRequest, NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";

// GET handler
export async function GET(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const { id } = params;
    const { searchParams } = new URL(request.url);
    const keys = searchParams.get("keys")?.split(",").filter(Boolean);

    const record = await prisma.jsonStore.findUnique({
      where: { id },
    });

    if (!record) {
      return NextResponse.json(
        { success: false, error: "Record not found" },
        { status: 404 }
      );
    }

    const content = keys
      ? Object.fromEntries(
          Object.entries(record.data as Record<string, unknown>).filter(
            ([key]) => keys.includes(key)
          )
        )
      : record.data;

    return NextResponse.json({
      success: true,
      data: {
        content,
        metadata: {
          id: record.id,
          created_at: record.createdAt,
          updated_at: record.updatedAt,
        },
      },
    });
  } catch (error) {
    console.error("GET Error:", error);
    return NextResponse.json(
      { success: false, error: "Internal server error" },
      { status: 500 }
    );
  }
}

// PUT handler
export async function PUT(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const { id } = params;
    const body = await request.json();

    const existingRecord = await prisma.jsonStore.findUnique({ where: { id } });
    const existingData =
      (existingRecord?.data as Record<string, unknown>) ?? {};

    const record = await prisma.jsonStore.upsert({
      where: { id },
      create: {
        id,
        data: body,
      },
      update: {
        data: {
          ...existingData,
          ...body,
        },
      },
    });

    return NextResponse.json({
      success: true,
      data: {
        content: record.data,
        metadata: {
          id: record.id,
          created_at: record.createdAt,
          updated_at: record.updatedAt,
        },
      },
    });
  } catch (error) {
    console.error("PUT Error:", error);
    return NextResponse.json(
      { success: false, error: "Internal server error" },
      { status: 500 }
    );
  }
}
